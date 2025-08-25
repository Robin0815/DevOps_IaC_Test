hello_world:
  cmd.run:
    - name: echo "Hello World from SaltStack!"

system_info:
  cmd.run:
    - name: uname -a

current_time:
  cmd.run:
    - name: date

scheduled_task:
  schedule.present:
    - function: cmd.run
    - job_args:
      - echo "Scheduled task executed at $(date)"
    - seconds: 300  # Run every 5 minutes