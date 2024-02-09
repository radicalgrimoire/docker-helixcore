# helixcore

This is the Dockerfile prepared by radicalgrimoire(六魔辞典).  
Container image files are available in GithubPackage, so feel free to use them if you are interested.

# How to use

## Built Container command

```
docker-compose -f docker-compose.yml up -d
```

## Go inside the container you built.

```
docker exec -it helix-p4d bash
```

## Enter the Perforce container and change to a perforce user

```
su perforce -
```

## Once you have changed to the perforce user, execute the command to log in to perforce

※ To make the p4 trigger work.

```
p4 login
```


