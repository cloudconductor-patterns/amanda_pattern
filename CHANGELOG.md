CHANGELOG
=========

## version 1.1.0 (2015/09/30)

  - Support CloudConductor v1.1.
  - Remove the event_handler.sh, modified to control by the Metronome (task order control tool).Therefore, add the requirements(task.yml file etc.) to control from the Metronome.
  - Remove cloud_conductor_util gem from the required gems.
  - Add the requirements for test run in test-kitchen.
  - Support prefix parameter when backup and restore.

## versoin 1.0.1 (2015/04/16)

  - Fix restore process to skip restoring to avoid no_such_bucket_error in case that the target bucket does not exist.

## version 1.0.0 (2015/03/27)

  - First release of amanda pattern that provides user with backup feature.
