# vim ssh-trust.sh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bakup
sed -i 's/\#Port 22/Port 51222/;s/\#RSAAuthentication yes/RSAAuthentication yes/;s/\#PubkeyAuthentication yes/PubkeyAuthentication yes/;s/\#AuthorizedKeysFile .ssh\/authorized_keys/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
systemctl restart sshd

ssh-keygen -t rsa

ssh-copy-id -i ~/.ssh/id_rsa.pub -p 51222 root@172.16.0.2

ssh-copy-id -i ~/.ssh/id_rsa.pub -p 51222 root@172.16.0.3

ssh-copy-id -i ~/.ssh/id_rsa.pub -p 51222 root@172.16.0.5

```
# CentOS6
/etc/init.d/sshd restart

scp ~/.ssh/id_rsa.pub root@host1:~/.ssh/id_rsa.pub.host2

scp ~/.ssh/id_rsa.pub root@host1:~/.ssh/id_rsa.pub.host3

cat id_rsa.pub >> authorized_keys
cat id_rsa.pub.host2 >> authorized_keys
cat id_rsa.pub.host3 >> authorized_keys

chmod 644 ~/.ssh/authorized_keys

scp ~/.ssh/authorized_keys root@host2:~/.ssh/

scp ~/.ssh/authorized_keys root@host3:~/.ssh/
```