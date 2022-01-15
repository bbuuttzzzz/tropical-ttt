#Tropical TTT

##Local
GMDS must be installed somewhere for this to work!
run `gmds-attach.sh <GMDS root folder>`

##Docker
Just build with docker for example `docker build --tag ttt .`

to run the image with docker, you need to include the related ports so something like
docker run -t -p 27015:27015/udp -p 27015:27015 -p 27005:27005/udp --name ttt tropical.azurecr.io/tropical-ttt:latest
