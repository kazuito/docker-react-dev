# docker-react-dev
Scripts for React application development using Docker

## TL;DR
```
./run.sh start [your_app]
```
Your application files are in `./apps/[your_app]`.

## Usage
```
./run.sh COMMAND
```

`COMMAND` is one of:
* `start [app_name]` or `run [app_name]`: Automatically set up `[app_name]` (run `create` and `install`) and start application
* `build`: Build Docker image
* `rebuild`: Re-build Docker image (if the iamge exists, delete it and build again)
* `create [app_name]`: Create your app (Equivalent to run `create-react-app [app_name]`)
* `install [app_name]`: Install npm modules (Equivalent to run `npm install`)
