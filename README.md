# Minetest Discord Webhook

This is a simple Minetest mod, that sends Messages to Discord via a Webhook, whenever a user joins or leaves, the server starts or shuts down and on every chat message. With this mod you can easily connect your Mintest game to your Discord server.



## Getting started

### Install Minetest Mod

To install this mod, you have two options:

* Clone this repository into the `minetest/mods` directory by executing

  ```shell
  git clone https://github.com/activivan/mt-dcwebhook.git
  ```

* Download this repository as an Archive: https://github.com/activivan/mt-dcwebhook/archive/refs/heads/master.zip 

  Extract the archive into the `minetest/mods` directory

### Creating a Discord Webhook

1. Go to your Discord server settings
2. Go to "Integrations"
3. Go to "Webhooks" and create a new Webhook
4. Copy the URL of the Webhook to your clipboard

### Configuring the mod

5. Open `minetest.conf` and add your copied Discord Webhook URL like so:

   ```conf
   dcwebhook_url = https://discord.com/api/webhooks/blablabla
   ```

6. Optionally you can set the language of the messages with lang codes (currently available: English: `en`, German: `de` and Russian: `ru`)

   ```conf
   lang = de
   ```

### Add mod to http_mods

As this mod uses the Minetest HTTP API to work, it has to be added to the `secure.http_mods` property in the `minetest.conf` file. Alternatively it can be added to `secure.trusted_mods`



# License

Copyright 2021 activivan <activivan.studios@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the  "Software"), to deal in the Software without restriction, including  without limitation the rights to use, copy, modify, merge, publish,  distribute, sublicense, and/or sell copies of the Software, and to  permit persons to whom the Software is furnished to do so, subject to  the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.