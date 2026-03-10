https://www.reddit.com/r/Slack/comments/odzfp8/browser_sign_in_does_not_redirect_back_to_the/

 It's the CLI lower-casing things it should not.

An answer at Stack Overflow helped me solving the issue.

In short, you run this on yout Terminal:

while sleep .1; do ps aux | grep slack | grep -v grep | grep magic; done

then you try to sign-in again. So when the browser tries to open slack, the tab runiing the command above will output something like this:

kde-open5 slack://WORKSPACE_ID/magic-login/...
/usr/lib/slack/slack --enable-crashpad slack://workspace_id/magic-login/...

So you copy the output and stop the bash script (Ctrl+C)

Then you paste the copied block and replace the workspace_id part with the uppercase version of this 
