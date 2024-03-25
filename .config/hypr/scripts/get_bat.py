#!/usr/bin/env python3
import subprocess

def acpi_proccess():
    """
    Run acpi command & proccess it
    """
    acpi = subprocess.run(['acpi'], capture_output=True, text=True, check=False)
    acpi = acpi.stdout.strip().split(": ")
    acpi = acpi[1].split(", ")[:2]
    acpi[1] = int(acpi[1][:2])
    ico="󱊣"
    if acpi[0]=="Charging":
        if acpi[1]<20:
            ico = "󰢟"
        elif acpi[1] <60:
            ico = "󱊤"
        else:
            ico = "󱊥"
    if acpi[0]=="Discharging":
        if acpi[1]<20:
            ico = "󰂎"
        elif acpi[1] <60:
            ico = "󱊡"
        else:
            ico = "󱊢"
    return ico+" "+str(acpi[1])+"%"

print(acpi_proccess())
