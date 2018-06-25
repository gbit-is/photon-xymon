# photon-xymon
PhotonOS Xymon Client


# What is this ?

It's a small Xymon client, written in bash using the limited tools avaivable in PhotonOS.
It sends: Disk, Inode, CPU and Memory information to a Xymon server from the PhotonOS machine directly.


# So, How do I use it ?

Well, since PhotonOS doesn't have cron I just use a secondary bash script I run with nohup 

while true;do
        ~script.sh > /dev/null;
        sleep 300;
done



### Configurations

The first few lines include all the thresholds and locations. The code is also heavily commented so it is easy to adjust it to your needs





## Authors

* **Gbit** - [Gbit-is](https://github.com/gbit-is)


## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE
