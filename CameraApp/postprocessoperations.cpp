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


#include "postprocessoperations.h"
#include "adddatestamp.h"

PostProcessOperations::PostProcessOperations(QObject *parent) :
    QObject(parent)
{
}

void PostProcessOperations::addDateStamp(const QString & path, QString dateFormat, QColor  stampColor,float   opacity, int alignment)
{

    this->workingThread = new AddDateStamp(path, dateFormat, stampColor, opacity, alignment);
    connect(this->workingThread, &AddDateStamp::finished, this->workingThread, &QObject::deleteLater);
    this->workingThread->start();
}
void PostProcessOperations::deleteEXIFdata(const QString &path)
{
    #if EXIV2_TEST_VERSION(0,28,0)
      Exiv2::Image::UniquePtr imgFile;
    #else
      Exiv2::Image::AutoPtr imgFile;
    #endif
    imgFile = Exiv2::ImageFactory::open(path.toStdString());
    imgFile->readMetadata();
    Exiv2::ExifData &exifData = imgFile->exifData();
    #if EXIV2_TEST_VERSION(0,28,0)
      long orientationFlags  = exifData["Exif.Image.Orientation"].toUint32();
    #else
      long orientationFlags  = exifData["Exif.Image.Orientation"].toLong();
    #endif
    imgFile->clearMetadata();
    exifData["Exif.Image.Orientation"] = std::to_string(orientationFlags);
    imgFile->writeMetadata();
}