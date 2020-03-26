import os
import boto3
import subprocess
from datetime import datetime, timezone, timedelta

def handler(event, context):
    clone_repo()

    last_commit_at = get_last_commit()
    print("Last commit at: {}".format(last_commit_at))

    now = datetime.now().astimezone(tz=timezone.utc)
    if last_commit_at >= now - timedelta(days=1):
        run_ec2_builder()

def clone_repo():
    subprocess \
        .Popen(["git", "clone", "--depth", "1", "--branch", "pve-kernel-5.3", "git://git.proxmox.com/git/pve-kernel.git", "/tmp/pve-kernel"], stdout=subprocess.PIPE, stderr=subprocess.PIPE) \
        .communicate()

def get_last_commit():
    date_str = subprocess \
        .Popen(["git", "log", "-1", "--format=%cd"], cwd="/tmp/pve-kernel", stdout=subprocess.PIPE) \
        .communicate()[0].decode("utf-8").strip()
    return datetime.strptime(date_str, "%a %b %d %H:%M:%S %Y %z").astimezone(tz=timezone.utc)

def run_ec2_builder():
    boto3.client('ec2').run_instances(LaunchTemplate={
        'LaunchTemplateName': os.environ['LAUNCH_TEMPLATE_NAME'],
        'Version': '$Latest'
    }, MinCount=1, MaxCount=1)

    print("Builder EC2 launched.")
