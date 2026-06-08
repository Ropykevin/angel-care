#!/usr/bin/env python3
import os
import sys
from pathlib import Path
from urllib.parse import quote_plus


def load_env(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, _, value = line.partition('=')
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key.strip(), value)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    load_env(root / '.env')

    required = ('POSTGRES_USER', 'POSTGRES_PASSWORD', 'POSTGRES_DB')
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        print(f'Missing in .env: {", ".join(missing)}', file=sys.stderr)
        return 1

    user = os.environ['POSTGRES_USER']
    password = quote_plus(os.environ['POSTGRES_PASSWORD'])
    host = '127.0.0.1'
    port = os.environ.get('POSTGRES_PORT', '5432')
    database = os.environ['POSTGRES_DB']
    url = f'postgresql://{user}:{password}@{host}:{port}/{database}'

    out = root / '.env.docker-runtime'
    out.write_text(f'DATABASE_URL={url}\n', encoding='utf-8')
    print(f'Wrote {out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
