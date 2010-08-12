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
#include <argp.h>

static argp_option options[] =
{
	{ "cellWidth", 'x', NULL, "integer", NULL, "Width of cell" },
	{ "cellHeight", 'y', NULL, "integer", NULL, "Height of cell" },
	{ "rows", 'r', NULL, "integer", NULL, "Number of cell rows" },
	{ "cols", 'c', NULL, "integer", NULL, "Number of cell columns" },
	{ "help", 'h', NULL, NULL, NULL, "Print help" },
	{ 0 }
};

static struct Options
{
	int cellWidth;
	int cellHeight;
	int rows;
	int cols;
	bool help;
	char *name;
};

static error_t parseOpt(int key, char *arg, argp_state *state)
{
	Options *o = (Options*)state->input;
	switch(key)
	{
		case 'h':
			o->help = true;
			break;
		case 'x':
			o->cellWidth = atoi(arg);
			break;
		case 'y':
			o->cellHeight = atoi(arg);
			break;
		case 'r':
			o->rows = atoi(arg);
			break;
		case 'c':
			o->cols = atoi(arg);
			break;
		case ARGP_KEY_ARG:
			o->name = arg;
			break;
		default:
			return ARGP_ERR_UNKNOWN;
	}
	
	return 0;
}


static argp argpDef = { options, parseOpt, "", "" };


int main(int argc, char **argv)
{
	Options o;
		
	o.cellWidth = -1;
	o.cellHeight = -1;
	o.rows = -1;
	o.cols = -1;
	o.help = false;
	o.name = NULL;
	opterr = 0;
	int c;
	
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
	loadPNG(o.name, &img);
	
	if(o.cols > 0 && o.cellWidth <= 0)
		o.cellWidth = img.width/o.cols;
	if(o.cellWidth > 0 && cols <= 0)
		o.cols = img.width/o.cellWidth;
	if(o.rows > 0 && o.cellHeight <= 0)
		o.cellHeight = img.height/o.rows;
	if(o.cellHeight > 0 && rows <= 0)
		o.rows = img.height/o.cellHeight;
	
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
