Select the HID device from your browser.

Open chrome://device-log/. You should see an error like the following indicating that the device cannot be accessed (where X is a number):

HIDEvent[19:07:01] Failed to open '/dev/hidrawX': FILE_ERROR_ACCESS_DENIED
HIDEvent[19:07:01] Access denied opening device read-write, trying read-only.

3. Grant read/write permissions in the Terminal:

$ sudo chmod o+rw /dev/hidrawX

4. Try opening the HID device from your browser again. This should likely work.

5. After you are finished with the setup, revert the permissions:

$ sudo chmod o-rw /dev/hidrawX


