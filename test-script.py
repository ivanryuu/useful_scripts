#!/usr/bin/python

import os.path
import sys
import getopt
import re
import time
import paramiko
import textwrap

auth_file = "~/.tdedev-config"
cmd_file = '~/.test_update_script_cmd'
update_script = ""
remote_dir = "/root/release/Devel/"

def parse_auth_file():
    selected_auth_file = open(auth_file, 'r');
    selected_auth_file.seek(0)
    lines = selected_auth_file.readlines()
    ip = lines[0].strip()
    (username, password) = lines[1].strip().split(',')
    return (ip, username, password)

def copy_to_remote(session, localpath, remotepath):
    sftp = session.open_sftp()
    if os.path.isfile(localpath):
        print "* sending update script to remote server..."
        sftp.put(localpath, remotepath)
    else:
        raise IOError('Could not find localfile %s' % localpath)
    sftp.close()

def open_ssh_conn():
    try:
        (ip, username, password) = parse_auth_file()

        session = paramiko.SSHClient()
        session.load_host_keys(os.path.expanduser(os.path.join("~", ".ssh", "known_hosts")))
        session.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        print "* connecting to %s" % ip
        session.connect(ip, username = username, password = password)

        copy_to_remote(session, update_script, remote_dir + update_script)

        connection = session.invoke_shell()
        time.sleep(1)

        commands = ""
        with open(cmd_file, 'r') as myfile:
            commands = myfile.read().replace("<update_script>", update_script)

        print "* sending commands to server..."
        for cmd in commands.split('\n'):
            connection.send('\\\n'.join(textwrap.wrap(cmd)) + '\n')
            time.sleep(2)

        print connection.recv(65535)

        session.close()
    except paramiko.AuthenticationException:
        print sys.exc_info()

myopts, args = getopt.getopt(sys.argv[1:], "c:f:a:")

for opt, arg in myopts:
    if opt == '-a':
        auth_file = arg
    elif opt == '-c':
        cmd_file = arg
    elif opt == '-f':
        update_script = arg
    else:
        print("Usage: %s -a auth_file -c cmd_file -f update_script" % sys.argv[0])

open_ssh_conn()
