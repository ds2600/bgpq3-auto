# bgpq3-auto

**What is it**  
bgpq3-auto is a simple shell script to run with cron that will run a bgpq3 query against ARIN, ALTDB, RADb, Level3, NTTCOM, and RIPE for the AS-NAMES designated as arguments. It will then generate a Cisco prefix list in a file and put it in a locally created file for that AS. 

**SendGrid**  
Currently, the script will try and use SendGrid to send an update email whether you have it configured or not. I will likely push an update in the future to be used without email and/or with SMS via Twilio.

**Configuration**  
Setup and use is pretty self explanatory:

    mkdir bgpq3-auto
    cd bgpq3-auto
    wget https://raw.githubusercontent.com/ds2600/bgpq3-auto/master/bgpq3-auto.sh
    wget https://raw.githubusercontent.com/ds2600/bgpq3-auto/master/.env.example
    chmod +x bgpq3-auto.sh
    cp .env.example .env

Using nano or vim, modify the existing .env to change the SendGrid integration variables to your environment. Then just run the script:

    ./bgpq3-auto.sh fastly
