#!/usr/bin/perl

#----------------------------------------------#
# unpacket
#----------------------------------------------#
use File::Path;
use File::Basename;
use Archive::Zip;

my @crc16_table = (
        0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
        0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
        0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
        0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
        0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
        0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
        0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
        0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
        0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
        0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
        0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
        0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
        0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
        0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
        0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
        0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
        0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
        0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
        0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
        0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
        0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
        0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
        0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
        0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
        0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
        0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
        0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
        0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
        0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
        0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
        0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
        0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040 );     

my $number 	= scalar @ARGV;	
my $i				= 0;
if($number<1)
{
	print "Usage: unpac.pl <pac-file> [out-path] [-S] [-D]\n";
	print "Usage: unpac.pl <-pac pac-file> [-out out-path] [-S] [-D]\n";
	die "[unpac.pl] Invalid parameters, At least input one pac file.\n";
}
#-S : CRC by pass
#-D	: Debug,out more info
print "\narg num:".$number."\n";

print "\n\n--------------------------------------\n";
for($i=0;$i<$number;$i++)
{
	print ${ARGV[$i]}." "
}
print "\n--------------------------------------\n\n";
					

my $PAC_MAGIC					= 0xFFFAFFFA;
my $ZIP_MAGIC					= 0x04034B50;
my $SIZEOF_PAC_HEADER = 2124;
my $SIZEOF_FILE_T 		= 2580;

my $pac_file;
my $szRelease_dir;
my $g_bCheckCRC	= 1;
my $g_bDebug		= 0;
my $g_isZipFile	= 0;

for($i = 0; $i<$number; $i++)
{
	$parm_temp = ${ARGV[$i]};
	if(lc($parm_temp) eq "-pac")
	{
		if(($i+1) < $number)
		{
			$pac_file = ${ARGV[$i+1]};
			if($pac_file && !-f $pac_file)
			{
				die "\nInvalid parameters, file [".$pac_file."] don't exist.\n";
			}
		}
		else
		{
			die "[unpac.pl] param error,no find pac file.\n";
		}
	}
	elsif (lc($parm_temp) eq "-out")
	{
		if(($i+1) < $number)
		{
			$szRelease_dir = ${ARGV[$i+1]};
		}
		else
		{
			die "[unpac.pl] param error,no find release path.\n";
		}
	}
	elsif (lc($parm_temp) eq lc("-S"))
	{
		$g_bCheckCRC	= 0;
	}
	elsif (lc($parm_temp) eq lc("-D"))
	{
		$g_bDebug	= 1;
	}
	elsif ($i == 0)
	{
		$pac_file = ${ARGV[0]};
	}
	elsif ($i == 1)
	{
		$szRelease_dir = ${ARGV[1]};
	}
}

if(!$szRelease_dir)
{
	$szRelease_dir	= dirname($pac_file);
	$szRelease_dir	= $szRelease_dir ."/ImageFiles/";
	
}
if( -d $szRelease_dir)
{
	rmtree($szRelease_dir);
}
$szRelease_dir =~ s/\\/\//g;
{
	if(substr($szRelease_dir,length($szRelease_dir)-1,1) ne "/")
	{
		$szRelease_dir = $szRelease_dir."/";
  }
}
mkdir $szRelease_dir or die "\nFailure to create unpacket dir[".$szRelease_dir."].\n";

#print "Pac file			:".$pac_file."\n";
print "unpacket Path	:".$szRelease_dir."\n";
 
my $totalSize = 0;
#[[ pack file header
my $szVersion; 			# packet struct version, unicode, total size is 44 bytes
my $dwHiSize;           # the whole packet hight size, 4 bytes
my $dwLoSize;           	# the whole packet low size, 4 bytes
my $szPrdName;   		# product name, total size is 512 bytes
my $szPrdVersion;       	# product version, total size is 512 bytes
my $nFileCount;         	# the number of files that will be downloaded, the file may be an operation, 4 bytes
my $dwFileOffset;		# the offset from the packet file header to the array of FILE_T struct buffer, 4 bytes
my $dwMode;			# 4 bytes
my $dwFlashType;		# 4 bytes
my $dwNandStrategy;		# 4 bytes
my $dwIsNvBackup;		# 4 bytes
my $dwNandPageType;		# 4 bytes
my $szPrdAlias;    		# 200 bytes
my $dwOmaDmProductFlag;		# 4 bytes
my $dwIsOmaDM;			# 4 bytes
my $dwIsPreload;		# 4 bytes
my $dwReserved;			# 800 bytes
my $dwMagic;			# 4 bytes
my $wCRC1;			# 2 bytes
my $wCRC2;			# 2 bytes
#]] total 2124 bytes

my $PacHeaderBuf;
my $FileInfoBuf;

my $start 	= time();
my $pac_size = -s $pac_file;
if($pac_size < $SIZEOF_PAC_HEADER)
{
	die "Bin packet's size is too small,maybe it has been destructed!";
}

my $szCfgFile = $szRelease_dir."flash.cfg";
my $ProductCfg = "\n[Setting]\n";
my $ImageCfg = "\n[FlashParam]\n";
my $CFGFILE;
open(CFGFILE, "+>$szCfgFile") or die "Can't create $szCfgFile";

my $PACFILE;
open(PACFILE, "<$pac_file") or die "Can't open $pac_file";
binmode PACFILE;
read PACFILE,$PacHeaderBuf,$SIZEOF_PAC_HEADER; #2124
	
my $dwZipMAGIC	= substr($PacHeaderBuf,0   ,4);
$dwZipMAGIC			= UnPack2DWORD($dwZipMAGIC);	
if( $dwZipMAGIC == $ZIP_MAGIC)
{
	$g_isZipFile = 1;
}

if ($g_isZipFile == 1) #zip file
{
	print "\nzip pac.\n";
	close PACFILE;
	my $zip = Archive::Zip->new();	
	unless ( $zip->read($pac_file) == AZ_OK ) 
	{
	    die 'Failure to read error\n';
	}
	else 
	{
		$zip->extractTree('',$szRelease_dir);
	}
}
else	#pac file
{
	print "\nsprd pac.\n";
	GetPacHeaderInfo();
	$totalSize = $dwHiSize*0x100000000 + $dwLoSize;
	if($totalSize != $pac_size)
	{
		die "Bin packet's size is not correct,maybe it has been destructed!\n";
	}
	if( $g_bCheckCRC == 1 )
	{
		CheckCrc();
	}
	
	seek PACFILE,$SIZEOF_PAC_HEADER,SEEK_SET;
	read PACFILE,$FileInfoBuf,$SIZEOF_FILE_T*$nFileCount;
	if ($g_bDebug	== 1)
	{
		for($i=0; $i<$nFileCount; $i++)
		{
		   GetFileInfo($i); 
		}
	}
	ReleaseDLFile(); 
	print CFGFILE $ProductCfg;
	print CFGFILE $ImageCfg;
	close CFGFILE;
	close PACFILE;
}


my $end = time();
print "\n---------------------------\n";
print "\nunpacket success\n\n";
print "unpacket path : $szRelease_dir\n";
print "total time	: " . ($end-$start) . "s\n";
print "---------------------------\n\n";

exit 0;

sub GetPacHeaderInfo{
	$szVersion 					= substr($PacHeaderBuf,0   ,44);			# 44 bytes
	$dwHiSize	 				= substr($PacHeaderBuf,44  ,4);				# 4 bytes
	$dwLoSize	 				= substr($PacHeaderBuf,48  ,4);				# 4 bytes
	$szPrdName 					= substr($PacHeaderBuf,52  ,512);   		# 512 bytes
	$szPrdVersion	 			= substr($PacHeaderBuf,564 ,512); 			# 512 bytes
	$nFileCount	 				= substr($PacHeaderBuf,1076,4);    			# 4 bytes
	$dwFileOffset 				= substr($PacHeaderBuf,1080,4);				# 4 bytes
	$dwMode		 				= substr($PacHeaderBuf,1084,4);				# 4 bytes
	$dwFlashType 				= substr($PacHeaderBuf,1088,4);				# 4 bytes
	$dwNandStrategy	 			= substr($PacHeaderBuf,1092,4);				# 4 bytes
	$dwIsNvBackup	 			= substr($PacHeaderBuf,1096,4);				# 4 bytes
	$dwNandPageType	 			= substr($PacHeaderBuf,1100,4);				# 4 bytes
	$szPrdAlias		 			= substr($PacHeaderBuf,1104,200);    		# 200 bytes
	$dwOmaDmProductFlag 		= substr($PacHeaderBuf,1304,4);				# 4 bytes
	$dwIsOmaDM				 	= substr($PacHeaderBuf,1308,4);				# 4 bytes
	$dwIsPreload			 	= substr($PacHeaderBuf,1312,4);				# 4 bytes
	#$dwReserved				= substr($PacHeaderBuf,1316,800);			# 800 bytes
	$dwMagic					= substr($PacHeaderBuf,2116,4);				# 4 bytes
	$wCRC1						= substr($PacHeaderBuf,2120,2);				# 2 bytes
	$wCRC2						= substr($PacHeaderBuf,2122,2);				# 2 bytes
	
	$szVersion 					= Unicode2Mbcs($szVersion);	
	$dwHiSize 					= UnPack2DWORD($dwHiSize);	
	$dwLoSize 					= UnPack2DWORD($dwLoSize);	
	$szPrdName 					= Unicode2Mbcs($szPrdName);	
	$szPrdVersion 				= Unicode2Mbcs($szPrdVersion);	
	$nFileCount 				= UnPack2DWORD($nFileCount);	
	$dwFileOffset 				= UnPack2DWORD($dwFileOffset);	
	$dwMode 					= UnPack2DWORD($dwMode);	
	$dwFlashType 				= UnPack2DWORD($dwFlashType);	
	$dwNandStrategy 			= UnPack2DWORD($dwNandStrategy);	
	$dwIsNvBackup 				= UnPack2DWORD($dwIsNvBackup);	
	$dwNandPageType 			= UnPack2DWORD($dwNandPageType);	
	$szPrdAlias 				= Unicode2Mbcs($szPrdAlias);	
	$dwOmaDmProductFlag 		= UnPack2DWORD($dwOmaDmProductFlag);	
	$dwIsOmaDM 					= UnPack2DWORD($dwIsOmaDM);	
	$dwIsPreload 				= UnPack2DWORD($dwIsPreload);		
	$dwMagic 					= UnPack2DWORD($dwMagic);		
	$wCRC1 						= UnPack2WORD($wCRC1);
	$wCRC2 						= UnPack2WORD($wCRC2);
	
	print "\n---------------------ProductInfo---------------------\n";
	print "Version=".$szVersion."\n";
	print "Size=".($dwHiSize*0x100000000+$dwLoSize)."\n";
	print "PrdName=".$szPrdName."\n";
	print "PrdVersion=".$szPrdVersion."\n";
	print "FileCount=".$nFileCount."\n";	
	print "FileOffset=".$dwFileOffset."\n";
	print "Mode=".$dwMode."\n";
	print "NandFlash=".$dwFlashType."\n";
	print "NandStrategy=".$dwNandStrategy."\n";
	print "IsNvBackup=".$dwIsNvBackup."\n";
	print "NandPageType=".$dwNandPageType."\n";
	print "PrdAlias=".$szPrdAlias."\n";
	print "OmaDmProductFlag=".$dwOmaDmProductFlag."\n";
	print "IsOmaDM=".$dwIsOmaDM."\n";
	print "IsPreload=".$dwIsPreload."\n";
	printf("Magic=0x%X.\n", $dwMagic);
	print "CRC1=".$wCRC1."\n";
	print "CRC2=".$wCRC2."\n";
	
	#Gen Product Info
	$ProductCfg = $ProductCfg."PacVer=".$szVersion."\n";
	$ProductCfg = $ProductCfg."PAC_PRODUCT=".$szPrdName."\n";
	$ProductCfg = $ProductCfg."ProductAlias=".$szPrdAlias."\n";
	$ProductCfg = $ProductCfg."ProductVer=".$szPrdVersion."\n";
	$ProductCfg = $ProductCfg."Mode=".$dwMode."\n";
	$ProductCfg = $ProductCfg."FlashType=".$dwFlashType."\n";
	$ProductCfg = $ProductCfg."NandStrategy=".$dwNandStrategy."\n";
	$ProductCfg = $ProductCfg."NandPageType=".$dwNandPageType."\n";
	$ProductCfg = $ProductCfg."NvBackup=".$dwIsNvBackup."\n";
	$ProductCfg = $ProductCfg."OmaDmProductFlag=".$dwOmaDmProductFlag."\n";
	$ProductCfg = $ProductCfg."OmaDM=".$dwIsOmaDM."\n";
	$ProductCfg = $ProductCfg."IsPreload=".$dwIsPreload."\n";
	
}

sub GetFileInfo
{
	
	#FileInfo Struct
	my $dwSize;					# size of this struct itself,4 bytes
	my $szFileID;				# file ID,such as FDL,Fdl2,NV and etc. 512 bytes
	my $szFileName;    	# file name,in the packet bin file,it only stores file name. 512 bytes
	                    # but after unpacketing, it stores the full path of bin file
	my $szFileVersion;	# Reserved now. 504 bytes
	my $dwHiFileSize;       # hight file size
	my $dwHiDataOffset;     # hight data offset
	my $dwLoFileSize;			# file size,4 bytes
	my $nFileFlag;      # 4 bytes
											# if "0", means that it need not a file, and 
	                    # it is only an operation or a list of operations, such as file ID is "FLASH"
	                    # if "1", means that it need a file
	                    
	my $nCheckFlag;     # 4 bytes
											# if "1", this file must be downloaded; 
	                    # if "0", this file can not be downloaded;										
	my $dwLoDataOffset;   # the offset from the packet file header to this file data,4 bytes
	my $dwCanOmitFlag;	# 4 bytes
											# if "1", this file can not be downloaded and not check it as "All files" 
											# in download and spupgrade tool.
	my $dwAddrNum;			# 4 bytes
	my $dwAddr;					# 4*5 bytes
	my $dwReserved;     # Reserved for future,not used now. 249x4 bytes
	#sizeof = 2580 bytes
	
	my $index 		= shift;
	my $data 		= substr($FileInfoBuf, $index*$SIZEOF_FILE_T,$SIZEOF_FILE_T);
	
  	$dwSize			= substr($data,0,4);			# 4 bytes
	$szFileID		= substr($data,4,512);			# 512 bytes
	$szFileName		= substr($data,516,512);    	# 512 bytes
	$szFileVersion 	= substr($data,1028,504);		# 504 bytes
	$dwHiFileSize 	= substr($data,1532,4);			# 4 bytes
	$dwHiDataOffset = substr($data,1536,4);			# 4 bytes
	$dwLoFileSize	= substr($data,1540,4);			# 4 bytes
	$nFileFlag		= substr($data,1544,4);      	# 4 bytes                
	$nCheckFlag		= substr($data,1548,4);     	# 4 bytes									
	$dwLoDataOffset	= substr($data,1552,4);   		# 4 bytes
	$dwCanOmitFlag	= substr($data,1556,4);			# 4 bytes
	$dwAddrNum		= substr($data,1560,4);			# 4 bytes
	#$dwAddr;						# 4*5 bytes
	#$dwReserved;     	# 249x4 bytes 
	
	$dwHiFileSize 	= UnPack2DWORD($dwHiFileSize);
	$dwLoFileSize 	= UnPack2DWORD($dwLoFileSize);
	$dwHiDataOffset = UnPack2DWORD($dwHiDataOffset);
	$dwLoDataOffset = UnPack2DWORD($dwLoDataOffset);
		
	$nFileSize 		= $dwHiFileSize*0x100000000 + $dwLoFileSize;
	$llDataOffset 	= $dwHiDataOffset*0x100000000 + $dwLoDataOffset;
	
	$dwSize 		= UnPack2DWORD($dwSize);	
	$szFileID 		= Unicode2Mbcs($szFileID);		
	$szFileName 	= Unicode2Mbcs($szFileName);	
	$nFileFlag 		= UnPack2DWORD($nFileFlag);	
	$nCheckFlag 	= UnPack2DWORD($nCheckFlag);	
	$dwCanOmitFlag	= UnPack2DWORD($dwCanOmitFlag);
	
	print "\n---------------------".($index+1)."---------------------\n";
	print "Size=".$dwSize."\n";
	print "FileID=".$szFileID."\n";
	print "FileName=".$szFileName."\n";
	print "FileSize=".$llFileSize."\n";
	print "FileFlag=".$nFileFlag."\n";
	print "CheckFlag=".$nCheckFlag."\n";
	print "DataOffset=".$llDataOffset."\n";
	print "CanOmitFlag=".$dwCanOmitFlag."\n";
  
}

sub ReleaseDLFile{
	my $nOffset = $SIZEOF_PAC_HEADER+$SIZEOF_FILE_T*$nFileCount;
	seek PACFILE,$nOffset,SEEK_SET;
	my $index = 0;
	for($index=0; $index<$nFileCount; $index++)
	{
		#FileInfo Struct
		my $dwSize;					# size of this struct itself,4 bytes
		my $szFileID;				# file ID,such as FDL,Fdl2,NV and etc. 512 bytes
		my $szFileName;    	# file name,in the packet bin file,it only stores file name. 512 bytes
		                    # but after unpacketing, it stores the full path of bin file
		my $szFileVersion;	# Reserved now. 504 bytes
		my $dwHiFileSize;       # hight file size
		my $dwHiDataOffset;     # hight data offset
		my $dwLoFileSize;			# file size,4 bytes
		my $nFileFlag;      # 4 bytes
												# if "0", means that it need not a file, and 
		                    # it is only an operation or a list of operations, such as file ID is "FLASH"
		                    # if "1", means that it need a file
		                    
		my $nCheckFlag;     # 4 bytes
												# if "1", this file must be downloaded; 
		                    # if "0", this file can not be downloaded;										
		my $dwLoDataOffset;   # the offset from the packet file header to this file data,4 bytes
		my $dwCanOmitFlag;	# 4 bytes
												# if "1", this file can not be downloaded and not check it as "All files" 
												# in download and spupgrade tool.
		my $dwAddrNum;			# 4 bytes
		my $dwAddr;					# 4*5 bytes
		my $dwReserved;     # Reserved for future,not used now. 249x4 bytes
		#sizeof = 2580 bytes
		
		
		my $data 		= substr($FileInfoBuf, $index*$SIZEOF_FILE_T,$SIZEOF_FILE_T);
		
	  	$dwSize			= substr($data,0,4);					# 4 bytes
		$szFileID		= substr($data,4,512);				# 512 bytes
		$szFileName		= substr($data,516,512);    	# 512 bytes
		$szFileVersion 	= substr($data,1028,504);			# 504 bytes
		$dwHiFileSize 	= substr($data,1532,4);			# 4 bytes
		$dwHiDataOffset = substr($data,1536,4);			# 4 bytes
		$dwLoFileSize	= substr($data,1540,4);				# 4 bytes
		$nFileFlag		= substr($data,1544,4);      	# 4 bytes                
		$nCheckFlag		= substr($data,1548,4);     	# 4 bytes									
		$dwLoDataOffset	= substr($data,1552,4);   		# 4 bytes
		$dwCanOmitFlag	= substr($data,1556,4);				# 4 bytes
		$dwAddrNum		= substr($data,1560,4);				# 4 bytes
		#$dwAddr;						# 4*5 bytes
		#$dwReserved;     	# 249x4 bytes 
		
		$dwHiFileSize 	= UnPack2DWORD($dwHiFileSize);
		$dwLoFileSize 	= UnPack2DWORD($dwLoFileSize);
		$dwHiDataOffset = UnPack2DWORD($dwHiDataOffset);
		$dwLoDataOffset = UnPack2DWORD($dwLoDataOffset);
			
		$nFileSize 		= $dwHiFileSize*0x100000000 + $dwLoFileSize;
		$dwDataOffset 	= $dwHiDataOffset*0x100000000 + $dwLoDataOffset;
		
		$dwSize 		= UnPack2DWORD($dwSize);	
		$szFileID 		= Unicode2Mbcs($szFileID);		
		$szFileName 	= Unicode2Mbcs($szFileName);	
		$nFileFlag 		= UnPack2DWORD($nFileFlag);	
		$nCheckFlag 	= UnPack2DWORD($nCheckFlag);	
		$dwCanOmitFlag	= UnPack2DWORD($dwCanOmitFlag);
			
		if($nFileSize >=$pac_size)
		{
			die "Read pakcet failed,maybe it has been destructed!\n";
			return FALSE;
		}
		if($nFileSize == 0)
		{
			if($nFileFlag == 1)
			{
				$ImageCfg = $ImageCfg.$szFileID."=0@\n";
			}
			else
			{
				$ImageCfg = $ImageCfg.$szFileID."=1@\n";
			}
			
			#printf("Magic = 0x%X.\n", $dwMagic);
			next;
		}
		
		my $szTmpFileName = $szFileName;
		my $szFilePath 	= $szRelease_dir.$szTmpFileName;
		$n=1;
		while(-f $szFilePath)
		{
			$szTmpFileName = $szFileName."(".$n.")";
			$szFilePath 	= $szRelease_dir.$szTmpFileName;
			$n++;
		}	
		$szFileName 		= $szTmpFileName;
		#print "szFilePath=".$szFilePath."\n";
		my $IMGFILE;
		open(IMGFILE, "+>$szFilePath") or die "Can't Create $szFilePath";
	    binmode IMGFILE; 
		my $left 			= $nFileSize;
		my $max_size 		= 64*1024;
	    my $buf; 
	    my $len;
	    seek PACFILE,$dwDataOffset,SEEK_SET;
		do{
			if($left > $max_size)
			{
				$len = $max_size;
			}
			else
			{
			  $len = $left;
			}
			read PACFILE,$buf,$len;	
			print IMGFILE $buf;
			$left -=  $len;
		}while($left>0);
		if($szFileID)
		{
			$ImageCfg = $ImageCfg.$szFileID."=1@".$szFileName."\n";
		}
		else
		{
			$ProductCfg= $ProductCfg."PAC_CONFILE=".$szFileName."\n";
		}
		
		close $FILE;
	}
	#print CFGFILE $configuration;
}

sub CheckCrc
{
	my $buf;
	my $wHeaderCRC1 = 0;
	my $wHeaderCRC2 = 0;
	my @part1 = ();
	if($dwMagic == $PAC_MAGIC)
	{
		#Check crc1
		print "\nCheck crc first part...\n";
		seek PACFILE,0,SEEK_SET;	
		read PACFILE,$buf,2120;
		@part1 = unpack("C" x 2120,$buf);  		
		$wHeaderCRC1 = crc16($wHeaderCRC1,@part1);	
		if($wHeaderCRC1 != $wCRC1)
		{
			print"CalcHeaderCRC1=".$wHeaderCRC1."\n";
			print"PacCRC1=".$wCRC1."\n";
			die "CRC1 Error! PAC file may be damaged!\n";
		}
		@part1=();
 	}
	
	#Check crc2
	print "\nCheck crc second part...\n";
	seek PACFILE,$SIZEOF_PAC_HEADER,SEEK_SET;
	my $size = $pac_size-2124;	
	my $max_size = 64*1024;
	my $left = $size;
	    
	do{
		if($left > $max_size)
		{
			$len = $max_size;
		}
		else
		{
			$len = $left;
		}		
		read PACFILE,$buf,$len;
		
		my @part = unpack("C" x $len,$buf); 	
		$wHeaderCRC2 = crc16($wHeaderCRC2,@part);	
		@part = ();
		$left -=  $len;	
	}while($left>0);	
	if($wHeaderCRC2 != $wCRC2)
	{
		print"CalcDataCRC2=".$wHeaderCRC2."\n";
		print"PacCRC2=".$wCRC2."\n";
		die "CRC2 Error! PAC file may be damaged!\n";
	}
	seek PACFILE,$SIZEOF_PAC_HEADER,SEEK_SET;
	return True;
}

sub Unicode2Mbcs{
    my ($d) = @_;
    $d =~s/\0//g; 
    return $d;
}

sub UnPack2DWORD{    
    my ($d) = @_;
    $d = unpack("V",$d);
    return $d;	
}

sub UnPack2WORD{    
    my ($d) = @_;
    $d = unpack("v",$d);
    return $d;	
}


        
sub crc16
{	
	my $crc    = shift;  
	my @data   = @_;
	foreach $b (@data) {$crc = (($crc >> 8)^( ${ crc16_table[ ($crc^$b) & 0xff] } )) & 0xFFFF;}	
	return $crc & 0xFFFF; 	        
}



