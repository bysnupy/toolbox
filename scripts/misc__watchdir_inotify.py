#! /usr/bin/env python

# Required inotiyfy api
# Usage: arg1: target directory
#
#-----------------------------------------

import inotify.adapters, logging, sys

log_format = '%(asctime)s :: %(name)s - %(levelname)s : %(message)s'

logger = logging.getLogger(__name__)
target_dir = sys.argv[1]

def config_logging():
  logger.setLevel(logging.DEBUG)

  handler = logging.StreamHandler()

  log_formatter = logging.Formatter(log_format)
  handler.setFormatter(log_formatter)

  logger.addHandler(handler)

def main():
  ino = inotify.adapters.Inotify()

  ino.add_watch(target_dir)

  try:
    for event in ino.event_gen():
      if event is not None:
        (header,  type_name, target_path, filename) = event
        logger.info("type: %s, path: %s, filename: %s" % (type_name, target_path, filename))
  finally:
    ino.remove_watch(target_dir)

if __name__ == '__main__':
  config_logging()
  main()
