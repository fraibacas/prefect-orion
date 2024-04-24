from prefect import flow, get_run_logger


@flow
def test_flow():
    logger = get_run_logger()
    logger.info("Hello from Prefect!")