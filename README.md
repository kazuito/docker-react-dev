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

`COMMAND` is one of (Details are below):
* `start APP_NAME` or `run APP_NAME`: Automatically set up `APP_NAME` (run `create` and `install`) and start application
* `build`: Build Docker image
* `rebuild`: Re-build Docker image (if the iamge exists, delete it and build again)
* `create APP_NAME`: Create your app (Equivalent to run `create-react-app APP_NAME`)
* `install APP_NAME`: Install npm modules (Equivalent to run `npm install`)

### Sub-command `start`
Run `build`, `create`, and `install` sub-command if needed, and start server.

#### Detailed usage
```
./run.sh start APP_NAME [PORT [OPTIONS...]]
```

* `APP_NAME`: Application (directory) name to start
* `PORT`: port to open (0 to hide all ports)
* `OPTIONS`: Any options to give to option (e.g. `-e NODE_ENV=production`)