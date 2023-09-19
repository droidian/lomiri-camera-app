/*
 * Copyright (C) 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <exiv2/exiv2.hpp>

#include "fileoperations.h"
#include <QtCore/QJsonObject>
#include <QtCore/QFile>
#include <QDebug>

FileOperations::FileOperations(QObject *parent) :
    QObject(parent)
{
}

bool FileOperations::remove(const QString & fileName) const
{
    return QFile::remove(fileName);
}

QJsonObject FileOperations::getEXIFData(const QString & path) const
{
     const std::string& exifPath = path.toStdString();
     Exiv2::Image::AutoPtr exifImageFile;
     QJsonObject retJson;
     try {
        exifImageFile = Exiv2::ImageFactory::open(exifPath);
        exifImageFile->readMetadata();
        Exiv2::ExifData &exifData = exifImageFile->exifData();

        for( Exiv2::ExifMetadata::iterator iter = exifData.begin(); iter != exifData.end(); iter++) {
                retJson[QString::fromStdString(iter->key())] = QString::fromStdString(iter->value().toString());
        }
     } catch (const std::exception& e) {
        qDebug() << "Failed when reading EXIF data : " <<  e.what();
     }

     return retJson;
}

bool FileOperations::setEXIFData(const QString & path, const QString & latitude, const QString & longitude) const
{
     const QString & exifPath = path;
     Exiv2::Image::AutoPtr exifImageFile = Exiv2::ImageFactory::open(exifPath.toStdString());
     try {
        exifImageFile->readMetadata();
        Exiv2::ExifData &exifData = exifImageFile->exifData();

        exifData["Exif.GPSInfo.GPSLatitude"] = latitude.toStdString();
        exifData["Exif.GPSInfo.GPSLongitude"] = longitude.toStdString();
        exifData["Exif.Image.Rating"] = 1;
        for( Exiv2::ExifMetadata::iterator iter = exifData.begin(); iter != exifData.end(); iter++) {
                qDebug() << QString::fromStdString(iter->value().toString());
        }
        exifImageFile->writeMetadata();
        return true;
     } catch (const std::exception& e) {
        qDebug() << "Failed when reading EXIF data : " <<  e.what();
     }
}
