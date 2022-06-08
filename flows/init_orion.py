import requests
import time


OUTPUT_ENV_FILE = './prefect.env'

ORION_SERVER_URL = 'http://localhost:4200'
GET_BLOCK_TYPES_URL = f'{ORION_SERVER_URL}/api/block_schemas/filter'
CREATE_BLOCK_URL = f'{ORION_SERVER_URL}/api/block_documents'
CREATE_WORK_QUEUE_URL = f'{ORION_SERVER_URL}/api/work_queues'
SET_DEFAULT_STORAGE_URL = f'{ORION_SERVER_URL}/api/block_documents/<BLOCK_ID_HERE>/set_default_storage_block_document'

session = requests.Session()


def init_storage(storage_type: str = 'File Storage', name: str = 'minio_docker'):
    storage_type: str = 'File Storage'
    name: str = 'minio_docker'
    # get block spec id for the storage type we want
    resp = session.post(GET_BLOCK_TYPES_URL, json={})
    resp.raise_for_status()
    block_schema = [ x for x in resp.json() if x['block_type']['name'] == storage_type ]
    if not block_schema:
        raise ValueError('<File Storage> not found')
    block_schema = block_schema[0]
    block_type_id = block_schema['block_type_id']
    block_schema_id = block_schema['id']

    # create storage block
    storage_options = dict(
        use_ssl = False,
        key = "blablabla",
        secret = "blablabla",
        client_kwargs = dict(endpoint_url = "http://minio:9000")
    )
    payload = dict(
        name = name,
        block_type_id = block_type_id,
        block_schema_id = block_schema_id,
        data = dict(base_path='s3://prefect-flows/', key_type="hash", options=storage_options)
    )
    resp = session.post(CREATE_BLOCK_URL, json=payload)
    resp.raise_for_status()
    block_id = resp.json()['id']
    # set sotrage as default
    resp = session.post(SET_DEFAULT_STORAGE_URL.replace('<BLOCK_ID_HERE>', block_id), json={})
    resp.raise_for_status()
    return block_id


def init_work_queue(name='docker_queue'):
    payload = dict(
        name = name,
        filter = dict(
            flow_runner_types = ['docker']
        )
    )
    resp = session.post(CREATE_WORK_QUEUE_URL, json=payload)
    resp.raise_for_status()
    return resp.json()['id']


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
    storage_id = init_storage()
    queue_id = init_work_queue()
    with open(OUTPUT_ENV_FILE, 'w') as f:
        f.write(f'STORAGE_ID={storage_id}\n')
        f.write(f'QUEUE_ID={queue_id}')


if __name__ == '__main__':
    main()
