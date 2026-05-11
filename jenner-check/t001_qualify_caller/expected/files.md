# Generated Files & Datasets

These URLs are tied to the run that produced them on the Jenner workspace at
[jenneranalytics.com](https://jenneranalytics.com) and expire when the run is
reaped. Re-running the bundle (via run_jenner.sh or by uploading script.sas to
the workspace) regenerates them.

When this bundle is submitted to the hosted Jenner API, the response includes
`files[]` and `datasets[]` arrays with relative URLs under
`/v1/run/{run_id}/`. The runner script `run_jenner.sh` prints the absolute
URLs for each artifact after a successful run.
