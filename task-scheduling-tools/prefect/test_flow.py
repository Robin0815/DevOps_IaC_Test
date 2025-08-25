from prefect import flow, task
import time

@task
def hello_task(name: str):
    print(f"Hello {name}!")
    time.sleep(2)
    return f"Hello {name}!"

@flow
def hello_flow(name: str = "World"):
    result = hello_task(name)
    print(f"Flow completed: {result}")

if __name__ == "__main__":
    hello_flow("Prefect")