FROM python:3

WORKDIR /usr/src/pm-graph
RUN  apt-get update && apt-get -y --no-install-recommends install \
usbutils pciutils
RUN pip install requests
COPY . .
CMD [ "python", "./sleepgraph.py"]
