#!/usr/bin/env python3

import json
import subprocess
import argparse


def is_package_needed(packages, package):
    if package['installed'][0]['installed_on_request']:
        return True
    for p in packages:
        for dep in p['dependencies']:
            if dep == package['name']:
                return True
    return False


def get_removables(packages):
    removables = []
    for package in packages:
        if is_package_needed(packages, package):
            continue

        removables.append(package)
        packages.remove(package)
        removables.extend(get_removables(packages))
        break
    return removables


def get_names(packages):
    names = []
    for package in packages:
        names.append(package['name'])
    return names


parser = argparse.ArgumentParser()
parser.add_argument("-n", "--dry-run", action="store_true")
parser.add_argument("-f", "--force", action="store_true")
args = parser.parse_args()

cmd = ["brew", "info", "--json", "--installed"]
output = subprocess.check_output(cmd)
jason = json.loads(output)
removables = get_removables(jason)
names = get_names(removables)

if len(names) == 0:
    exit()

for name in names:
    print(name)

if args.dry_run:
    exit()

if not args.force:
    input("==> Confirm?")

cmd = ["brew", "remove"]
cmd.extend(names)
subprocess.run(cmd)
