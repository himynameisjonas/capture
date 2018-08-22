# Capture - Requests

Caputure web requests, like webhooks, for debugging. With realtime updates!

## Installation

*Requires a running redis instance on localhost.*

* `yarn install`
* `bundle install`
* start with a `Procfile` runner


## Usage

It captures all requests when the path begins with `/c/`. For example `http://localhost:5000/c/foo/bar`. Visit root url to view captured requests.
