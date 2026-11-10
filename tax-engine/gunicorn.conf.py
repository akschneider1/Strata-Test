"""
Configuration file for the Gunicorn server used to run the application in production environments.

Attributes:
    bind(str): The socket to bind. Formatted as '0.0.0.0:$PORT'.
    workers(int): The number of worker processes for handling requests.
    threads(int): The number of threads per worker for handling requests.

For more information, see https://docs.gunicorn.org/en/stable/configure.html
"""

import os

from src.app_config import AppConfig

app_config = AppConfig()

bind = app_config.host + ':' + str(app_config.port)
# Each worker process loads its own copy of the tax rules (about 1.5 GB) and
# calculations are CPU-bound, so one worker can only use one core. Run one
# worker per container and add capacity by running more containers. Threads
# keep health checks and cached results responsive while a calculation runs.
# Set WEB_CONCURRENCY only on a host with a core and 1.5 GB to spare per worker.
workers = int(os.getenv("WEB_CONCURRENCY", "1"))
threads = int(os.getenv("WEB_THREADS", "8"))
