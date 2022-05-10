from prefect import flow, get_run_logger
from prefect.blocks.storage import FileStorageBlock
from prefect.deployments import DeploymentSpec
from prefect.flow_runners import DockerFlowRunner


@flow
def my_docker_flow():
    logger = get_run_logger()
    logger.info("Hello from Docker!")


DeploymentSpec(
    name="docker-example",
    flow=my_docker_flow,
    flow_runner=DockerFlowRunner(
        image = 'my-prefect-orion',
        image_pull_policy = 'IF_NOT_PRESENT',
        networks = ['prefect'],
        env = {
            "USE_SSL": False,
            "AWS_ACCESS_KEY_ID": "blablabla",
            "AWS_SECRET_ACCESS_KEY": "blablabla",
            "ENDPOINT_URL": 'http://minio:9000',
        }
    ),
    #flow_storage=FileStorageBlock(base_path="s3://minio-flows/", key_type="hash"),
)


"""

"""