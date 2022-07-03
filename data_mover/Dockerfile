FROM ubuntu

WORKDIR data-mover

RUN apt update \
    && apt upgrade -y \
    && apt install -y python3 python3-pip guestfs-tools parted 

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["/bin/bash","runner.sh"]