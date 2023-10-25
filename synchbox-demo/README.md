# Chris's SynchBox Example Script

## Overview

This is a minimum working script showing how to read SynchBox data that was
saved by the USE software suite.

As long as the "exp-utils-cjt" libraries are on path, this should work.

## What This Script Does

* First, a sample folder is selected. This is `samples-louie` for a typical
ephys session or `samples-marcus` for a typical computer session. For real
data, this should point to the `RuntimeData` folder created by USE.

* Raw serial data is read using `euUSE_readRawSerialData`. This saves
communications messages in a Matlab table.

* The "sent" data is parsed using `euUSE_parseSerialSentData`. This
returns a table containing all reward and event code commands that were
transmitted to the SynchBox.

* The "received" data is parsed using `euUSE_parseSerialRecvData`. This
returns a table containing all synchronization pulses, reward pulses,
and event codes that were actually sent by the SynchBox. __NOTE__ - Some
events that happened might not be reported in this list, if the
communications link was saturated.

* The "received" data is parsed using `euUSE_parseSerialRecvDataAnalog`.
This returns a table containing analog sensor readings that the SynchBox
reported. __NOTE__ - Some readings might not be reported, if the
communications link was saturated.

* All of these data tables are then saved in the "output" folder.


*This is the end of the file.*
