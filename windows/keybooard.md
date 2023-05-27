# How to share keyboard layout Japanese and English

## Condition

- Laptop keyboard: Japanense(106/109)
- External Keyboard: English(101/102)

## Settting

- You can save below code as keyboard.reg.

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\ACPI\DLLK0B46\4&2BE28486&0\Device Parameters]
"OverrideKeyboardType"=dword:00000007
"OverrideKeyboardSubtype"=dword:00000002
```

- run reg

- reboot your pc