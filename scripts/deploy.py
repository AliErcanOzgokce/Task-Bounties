#!/usr/bin/python3

from brownie import TaskBounties, accounts


def main():
    return TaskBounties.deploy({'from': accounts[0]})
