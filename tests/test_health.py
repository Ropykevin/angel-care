from app import create_app


def test_healthz():
    app = create_app()
    client = app.test_client()
    response = client.get('/healthz')
    assert response.status_code == 200
    assert response.data == b'ok'
