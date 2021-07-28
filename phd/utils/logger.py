import phd
import logging
import copy


# taken from yt and included a change to change file logs
# https://stackoverflow.com/questions/384076/how-can-i-color-python-logging-output
def add_coloring_to_emit_ansi(fn):
    def new(record):
        record = copy.copy(record)
        levelno = record.levelno
        if(levelno >= 50):
            color = '\x1b[31m'  # red
        elif(levelno >= 40):
            color = '\x1b[31m'  # red
        elif(levelno >= 30):
            color = '\x1b[33m'  # yellow
        elif(levelno >= 25):
            color = '\x1b[32m'  # green
        elif(levelno >= 20):
            color = '\x1b[32m'  # green
        elif(levelno >= 10):
            color = '\x1b[35m'  # pink
        else:
            color = '\x1b[0m'  # normal
        ln = color + record.levelname + '\x1b[0m'
        record.levelname = ln
        return fn(record)
    return new

# taken from yt
ufstring = "%(name)-3s: [%(levelname)-9s] %(asctime)s: %(message)s"
cfstring = "%(name)-3s: [%(levelname)-18s] %(asctime)s: %(message)s"

# setup logger
phdLogger = logging.getLogger('phd')

## create log stream
sh_handler = logging.StreamHandler()
sh_handler.setFormatter(logging.Formatter(cfstring))
phdLogger.addHandler(sh_handler)
original_emitter = sh_handler.emit
sh_handler.emit = add_coloring_to_emit_ansi(sh_handler.emit)

# add success to logger
logging.SUCCESS = 25
logging.addLevelName(logging.SUCCESS, 'SUCCESS')
phdLogger.success = lambda msg, *args, **kwargs: phdLogger.log(logging.SUCCESS, msg, *args, **kwargs)

logging.STARTUP = 22
logging.addLevelName(logging.STARTUP, 'STARTUP')
phdLogger.startup = lambda msg, *args, **kwargs: phdLogger.log(logging.STARTUP, msg, *args, **kwargs)

# make sure only processor zero logs
phdLogger.debug    = lambda msg, *args, **kwargs: phdLogger.log(logging.DEBUG, msg, *args, **kwargs)\
        if phd._rank == 0 else None
phdLogger.info     = lambda msg, *args, **kwargs: phdLogger.log(logging.INFO, msg, *args, **kwargs)\
        if phd._rank == 0 else None
phdLogger.success  = lambda msg, *args, **kwargs: phdLogger.log(logging.SUCCESS, msg, *args, **kwargs)\
        if phd._rank == 0 else None
phdLogger.warning  = lambda msg, *args, **kwargs: phdLogger.log(logging.WARNING, msg, *args, **kwargs)\
        if phd._rank == 0 else None
phdLogger.critical = lambda msg, *args, **kwargs: phdLogger.log(logging.CRITICAL, msg, *args, **kwargs)\
        if phd._rank == 0 else None
phdLogger.startup  = lambda msg, *args, **kwargs: phdLogger.log(logging.STARTUP, msg, *args, **kwargs)\
        if phd._rank == 0 else None
