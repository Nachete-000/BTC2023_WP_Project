from locust import HttpUser, task
class wp(HttpUser):
    @task
    def wp(self):
        self.client.get("/what-is-devops/")
        self.client.get("/privacy-policy/")
        self.client.get("/")
        self.client.get("/blog/category/uncategorized/")

import logging
from locust import events

@events.quitting.add_listener
def _(environment, **kw):
    if environment.stats.total.fail_ratio > 0.01:
        logging.error("Test failed due to failure ratio > 1%")
        environment.process_exit_code = 1
    elif environment.stats.total.avg_response_time > 5000:
        logging.error("Test failed due to average response time ratio > 5000 ms")
        environment.process_exit_code = 1
    elif environment.stats.total.get_response_time_percentile(0.95) > 5000:
        logging.error("Test failed due to 95th percentile response time > 5000 ms")
        environment.process_exit_code = 1
    else:
        environment.process_exit_code = 0