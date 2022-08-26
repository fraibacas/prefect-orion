import requests
import time


ORION_SERVER_URL = 'http://localhost:4200'

session = requests.Session()


def wait_for_server_ready(max_wait_seconds: int = 60):
    up = False
    deadline = time.time() + max_wait_seconds
    while time.time() <= deadline:
        print('waiting for prefect server to be ready...')
        try:
            resp = session.get(f'{ORION_SERVER_URL}/api/health')
            resp.raise_for_status()
            up = resp.json()
            if up is True:
                break
        except Exception:
            pass
        time.sleep(2)
    if not up:
        raise RuntimeError(f'prefect server not ready after {max_wait_seconds} seconds')


def main():
    wait_for_server_ready()


if __name__ == '__main__':
    main()
