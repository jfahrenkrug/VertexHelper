/*
 *  VertexScannerMain.cpp
 *  VertexHelper
 *
 *  Created by Peter Siroki on 2010.06.21.
 *
 */

#include "PNGLoader.h"
#include "VertexScanner.h"
#include <unistd.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
	int cellWidth = -1;
	int cellHeight = -1;
	int rows = -1;
	int cols = -1;
	opterr = 0;
	int c;
	bool help = false;
	
	while((c = getopt(argc, argv, "x:y:r:c:h")) != -1)
	{
		fprintf(stderr, "%c\n", c);
		switch(c)
		{
			case 'h':
				help = true;
				break;
			case 'x':
				cellWidth = atoi(optarg);
				break;
			case 'y':
				cellHeight = atoi(optarg);
				break;
			case 'r':
				rows = atoi(optarg);
				break;
			case 'c':
				cols = atoi(optarg);
				break;
			case '?':
				if(strchr("xyrc", optopt))
				{
					fprintf(stderr, "Option -%c requires an argument. See help for details.\n", optopt);
					return -1;
				} else
				{
					fprintf(stderr, "Unknown option: %c\n", optopt);
					return -1;
				}
				break;
		}
	}
	
	if(help || optind != argc-1 || argc <= 1 || (cellWidth <= 0 && cols <= 0) || (cellHeight <= 0 && rows <= 0))
	{
		fprintf(stderr, "Usage:\n\tVertexScanner -r <rows> -c <cols> <png-file>\n");
		return -1;
	}
	
	ImageDesc img;
	loadPNG(argv[optind], &img);
	
	if(cols > 0 && cellWidth <= 0)
		cellWidth = img.width/cols;
	if(cellWidth > 0 && cols <= 0)
		cols = img.width/cellWidth;
	if(rows > 0 && cellHeight <= 0)
		cellHeight = img.height/rows;
	if(cellHeight > 0 && rows <= 0)
		rows = img.height/cellHeight;
	
	if(cellWidth*cols > img.width)
	{
		fprintf(stderr, "Invalid width: %d (image width is %d)\n",
				int(cellWidth*cols),
				int(img.width));
		return -1;
	}
	
	if(cellHeight*rows > img.height)
	{
		fprintf(stderr, "Invalid height: %d (image height is %d)\n",
				int(cellHeight*rows),
				int(img.height));
		return -1;
	}
	
	for(int cy=0; cy<rows; cy++)
	{
		for(int cx=0; cx<cols; cx++)
		{
			ImageDesc cell;
			cell.width = cellWidth;
			cell.height = cellHeight;
			// the image is a top-down image
			cell.pitch = img.pitch;
			// so data will point to the last row
			cell.data = img.data;
			// also offset it by the coordinates of the cell
			cell.data += (cx*cellWidth*4)+(cy*cellHeight*img.pitch);
			
			Vec2Array points;
			points.points = NULL;
			
			findPoints(&cell, &points);
			
			printf("\n// Cell %d %d\n", cx, cy);
			if(points.count > 0)
			{
				for(int i=0; i<points.count; i++)
				{
					Vec2 p = points.points[i];
					p.x -= cellWidth*0.5f;
					p.y -= cellHeight*0.5f;
					printf("%g %g\n", p.x, p.y);
				}
			}
			
			if(points.points)
				free(points.points);
		}
	}
	
}
