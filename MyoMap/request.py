import urllib2
import json

def restaurant(lat, lng):
    key = "AIzaSyDb2G5vVPHEMXD32x2AQ0p1t3H0NxOsQms"
    location = str(lat) + "," + str(lng)
    contents = urllib2.urlopen("https://maps.googleapis.com/maps/api/place/nearbysearch/json?key="
                              + key +"&location=" + location + "&rankby=distance&type=restaurant").read()

    jsonContents = json.loads(contents)['results']
    #print(jsonContents)

    list = []
    for i in range(0,10):
        temp = jsonContents[i]
        try:
           c = temp['rating']
        except:
           c = 0
        list.append([temp['name'],
                     c,
                    temp['geometry']['location']['lat'],
                    temp['geometry']['location']['lng']])

    print(list)
    return list

#restaurant(43.4776419,-80.5303093) TEST 