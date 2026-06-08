from datetime import datetime

from flask import render_template, request, redirect, session, flash
from werkzeug.security import generate_password_hash, check_password_hash

from app.extensions import db
from app.models import User, Patient, Appointment, MedicalRecord


def register_routes(app):
    @app.route('/')
    def home():
        return render_template('home.html')

    @app.route('/healthz')
    def healthz():
        return 'ok', 200

    @app.route('/dashboard')
    def dashboard():
        if 'user_id' not in session:
            return redirect('/login')

        search = request.args.get('search', '')

        appointments = (
            Appointment.query
            .join(Patient)
            .filter(Patient.full_name.ilike(f'%{search}%'))
            .order_by(Appointment.appointment_date.desc())
            .all()
        )

        return render_template('dashboard.html', appointments=appointments)

    @app.route('/login', methods=['GET', 'POST'])
    def login():
        user_exists = User.query.first()

        if request.method == 'POST':
            if not user_exists:
                user = User(
                    username=request.form['username'],
                    password=generate_password_hash(request.form['password']),
                )
                db.session.add(user)
                db.session.commit()
                return redirect('/login')

            username = request.form['username']
            password = request.form['password']
            user = User.query.filter_by(username=username).first()

            if user and check_password_hash(user.password, password):
                session['user_id'] = user.id
                return redirect('/dashboard')

            flash('Invalid username or password')
            return redirect('/login')

        flash('Loged In Successfully')
        return render_template('login.html', user_exists=user_exists)

    @app.route('/delete/<int:id>')
    def delete(id):
        appointment = Appointment.query.get_or_404(id)
        db.session.delete(appointment)
        db.session.commit()
        flash('Appointment deleted successfully')
        return redirect('/dashboard')

    @app.route('/update/<int:id>', methods=['GET', 'POST'])
    def update(id):
        appointment = (
            Appointment.query
            .join(Patient)
            .filter(Appointment.id == id)
            .first()
        )

        if not appointment:
            return 'Appointment not found'

        if request.method == 'POST':
            appointment.appointment_date = datetime.fromisoformat(request.form['date'])
            appointment.reason = request.form['reason']
            appointment.status = request.form['status']
            db.session.commit()
            flash('Appointment updated successfully')
            return redirect('/dashboard')

        formatted_date = appointment.appointment_date.strftime('%Y-%m-%dT%H:%M')
        return render_template(
            'update.html',
            appointment=appointment,
            formatted_date=formatted_date,
        )

    @app.route('/update_status/<int:id>')
    def update_status(id):
        if 'user_id' not in session:
            return redirect('/login')

        appointment = Appointment.query.get_or_404(id)
        appointment.status = 'completed'
        db.session.commit()
        flash('Appointment marked as completed')
        return redirect('/dashboard')

    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if User.query.first():
            return 'Registration closed. Admin already exists.'

        if request.method == 'POST':
            user = User(
                username=request.form['username'],
                password=generate_password_hash(request.form['password']),
            )
            db.session.add(user)
            db.session.commit()
            return redirect('/login')

        return render_template('register.html')

    @app.route('/book', methods=['GET', 'POST'])
    def book():
        if request.method == 'POST':
            patient = Patient(full_name=request.form['name'])
            db.session.add(patient)
            db.session.flush()

            appointment = Appointment(
                patient_id=patient.id,
                appointment_date=datetime.fromisoformat(request.form['date']),
                reason=request.form['reason'],
            )
            db.session.add(appointment)
            db.session.commit()
            flash('Appointment Booked successfully')
            return redirect('/confirmation')

        return render_template('book.html')

    @app.route('/records/<int:patient_id>', methods=['GET', 'POST'])
    def records(patient_id):
        if 'user_id' not in session:
            return redirect('/login')

        if request.method == 'POST':
            record = MedicalRecord(
                patient_id=patient_id,
                diagnosis=request.form['diagnosis'],
                treatment=request.form['treatment'],
                notes=request.form.get('notes', ''),
            )
            db.session.add(record)
            db.session.commit()
            flash('Medical record saved')
            return redirect(f'/records/{patient_id}')

        records_list = (
            MedicalRecord.query
            .filter_by(patient_id=patient_id)
            .order_by(MedicalRecord.created_at.desc())
            .all()
        )

        return render_template('records.html', records=records_list, patient_id=patient_id)

    @app.route('/logout')
    def logout():
        session.clear()
        flash('Loged Out successfully')
        return redirect('/login')

    @app.route('/edit_record/<int:id>', methods=['GET', 'POST'])
    def edit_record(id):
        record = MedicalRecord.query.get_or_404(id)

        if request.method == 'POST':
            record.diagnosis = request.form['diagnosis']
            record.treatment = request.form['treatment']
            record.notes = request.form['notes']
            db.session.commit()
            return redirect(f'/records/{record.patient_id}')

        return render_template('edit_record.html', record=record)

    @app.route('/delete_record/<int:id>')
    def delete_record(id):
        record = MedicalRecord.query.get_or_404(id)
        patient_id = record.patient_id
        db.session.delete(record)
        db.session.commit()
        return redirect(f'/records/{patient_id}')

    @app.route('/confirmation')
    def confirmation():
        return render_template('confirmation.html')

    @app.route('/complete/<int:id>')
    def complete(id):
        if 'user_id' not in session:
            return redirect('/login')

        appointment = Appointment.query.get_or_404(id)
        appointment.status = 'completed'
        db.session.commit()
        return redirect('/dashboard')

    @app.route('/about')
    def about():
        return render_template('about.html')

    @app.route('/services')
    def services():
        return render_template('services.html')

    @app.route('/vision')
    def vision():
        return render_template('vision.html')

    @app.route('/contact')
    def contact():
        return render_template('contact.html')
