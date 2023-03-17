import xml.etree.ElementTree as ET
import pandas as pd
import os

def xml2csv(fname, delcols=[]):
    tree = ET.parse(fname)
    root = tree.getroot()
    d = pd.DataFrame([e.attrib for e in root])
    for name in delcols: del d[name]
    d.to_csv(fname+".csv", index=False)

def all_xml(path):
    for fname in os.listdir(path):
        print(fname)
        if fname.endswith(".xml"):
            xml2csv(path+fname)
        elif os.path.isdir(path+fname):
            all_xml(path+fname+'/')

if __name__ == "__main__":
    all_xml(os.getcwd() + '/data/')