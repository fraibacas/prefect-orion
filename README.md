# Prefect 2.0 docker compose deployment (Mac and Linux)

Scripts to deploy Prefect 2.0 locally configured with Postgres, a docker agent, and Minio for flow storage


### Requirements
    * docker
    * docker-compose
    * make


### Steps

    * Clone this repo at the location of your convenience
    * Add folowing entry to your /etc/hosts:
        127.0.0.1 prefect-server
    * Cd into the prefect-orion folder
    * Build docker image used by prefect server, agent and flow runner
        ```
        make docker
        ```
    * Start the stack
        ```
        ./prefect.sh start
        ```
        The prefect.sh script initializes postgres, creates a worker queue and starts all services. Data (postgres, minio) is stored in a folder named `volumes`
    * Give the start command a few seconds, specially the first time since postgres and prefect need to be initializated
    * Open http://prefect-server:4200 in your browser and verify Prefect UI is up and running
    * Deploy test flow
        ```
        make register-test-flow
        ```
        A flow named `my-docker-flow` should exist
    * Create a flow run from the UI by creating a `Quick Run` from the Flows view


    * To stop the services run `./prefect.sh stop`
    * To reset your environment, run `./prefect.sh reset && ./prefect.sh start`. A fresh deployment will start up.


### Notes
    * If running in linux, you may need to run as root depending on docker permissions