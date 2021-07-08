# iggy


**An easy-to-use Bash script to build and install Enlightenment on openSUSE Tumbleweed.**

See also [erode.sh](https://github.com/sensamillion/erode)

## Get started


First, clone this repository (you need the *git-core* or *git* package installed) from a terminal window:

```bash
git clone https://github.com/sensamillion/iggy.git .iggy
```

This creates a new hidden folder named **.iggy** in your home directory.

Please copy the file iggy.sh from this new folder to the download folder.

Now change to the download folder and make the script executable:

```bash
chmod +x iggy.sh
```

Then issue the following command:

```bash
./iggy.sh
```

On subsequent runs, open a terminal and simply type:

```bash
iggy.sh
```

(Use tab completion: Just type *igg* and press Tab)


### Update local repository


Be sure to check for updates at least once a week. In order to do this, change to ~/.iggy/ and run:

```bash
git pull
```

That's it.

Mind the cows! :cow2: :cow2: :cow2:
