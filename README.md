# Convert Google Documents HTML to structured well formed HTML

## Ubuntu 16.04

### Setup

```bash
pip install -r requirements.txt
```

### Usage

```bash
python run.py
```

Open web browser at `http://127.0.0.1:9000`

## Alternative use VirtualBox + Vagrant setup

```
vagrant up
vagrant ssh
cd /vagrant
python run.py
```

Open web browser at `http://127.0.0.1:9000`

## Some public test documents

* <https://docs.google.com/document/d/1m8ByaRhLodxxpPWWOoAouWE2xu-_FrKcznRoR9EB8jE/edit>
* <https://docs.google.com/document/d/1Ob217vTn_t_Zs81Beq6W81-mTrM_st8KJITK1t5sydY/edit>
* <https://docs.google.com/document/d/1OBIwM5mQQpswu1SKRjcX5CuAJ6tWXQtp7AYFskHEaBs/edit>

## Screenshot

![](http://i.imgur.com/DaWU9Sj.png)

## Known issues

* [ ] no session/multiuser support (one user at a time).
* [ ] no good support for big Google Docs documents with lots of images. Images are fetched into memory (yes, that's bad).
* [ ] no good temporary file handling and deletion