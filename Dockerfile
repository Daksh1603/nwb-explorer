FROM node:16 as jsbuild

ENV FOLDER=nwb-explorer


WORKDIR $FOLDER/webapp
COPY webapp/package-lock.json .
COPY webapp/package.json .
RUN npm ci
COPY webapp/ .
RUN npm run build
#Remove node_modules, need to keep the geppetto client
RUN mv node_modules/@geppettoengine .
RUN rm -Rf node_modules/*
RUN mv @geppettoengine node_modules

###
FROM jupyter/base-notebook:hub-1.1.0

ENV FOLDER=nwb-explorer
USER root
RUN jupyter labextension disable @jupyterlab/hub-extension
RUN apt-get update -qq &&\
    apt-get install python3-tk vim nano unzip git g++ -qq
  
COPY --chown=1000:1000 requirements.txt .   
RUN pip install -r requirements.txt --no-cache-dir
USER $NB_UID
COPY  . $FOLDER 
COPY --from=jsbuild --chown=1000:1000 $FOLDER $FOLDER

WORKDIR $FOLDER


# Update Browserslist
RUN cd webapp && npx browserslist@latest --update-db

RUN cd ../

# Temporary fix for deprecated api usage on some requirement
RUN pip install setuptools==45

USER root
RUN python utilities/install.py 


RUN rm -rf /var/lib/apt/lists
# sym link workspace pvc to $FOLDER
RUN chown -R $NB_UID .
RUN chown -R $NB_UID /opt/*


USER $NB_UID
CMD ./NWBE
