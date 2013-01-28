farm-scripts
============

Federated Wiki Farm Management Scripts

Install this repo in a `scripts` directory adjacent to the `pages` directory within which you
would like to create report pages that help you manage a wiki farm.

Invoke a script at your convenience or add a line to cron to run a script on a frequent schedule.

    node build.coffee

This builds a page `farm-activity` that contains a reference to the most recently edited 
page in each qualifying wiki in the farm. This page works well with the Activity plugin
to give a farm operator a sense of what is happening in the farm.
