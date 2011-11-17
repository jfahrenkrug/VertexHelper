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

enum ParameterType { P_NONE, P_INTEGER, P_FLOAT };

struct Arg
{
	const char *name;
	char shortName;
	ParameterType param;
	const char *desc;
	int optionOffset;
};

struct Options
{
	int cellWidth;
	int cellHeight;
	int rows;
	int cols;
	float minAngle;
	float maxAngle;
	bool help;
	char *name;
};

Options* const BASE = 0;

inline int offset(void *v) { return (int)reinterpret_cast<ssize_t>(v); }

static Arg options[] =
{
	{ "cellWidth", 'x', P_INTEGER, "Width of cell", offset(&BASE->cellWidth) },
	{ "cellHeight", 'y', P_INTEGER, "Height of cell", offset(&BASE->cellHeight) },
	{ "rows", 'r', P_INTEGER, "Number of cell rows", offset(&BASE->rows) },
	{ "cols", 'c', P_INTEGER, "Number of cell columns", offset(&BASE->cols) },
	{ "minAngle", 'a', P_FLOAT, "Minimum angle", offset(&BASE->minAngle) },
	{ "maxAngle", 'b', P_FLOAT, "Maximum angle", offset(&BASE->maxAngle) },
	{ "help", 'h', P_NONE, "Print help", offset(&BASE->help) },
	{ 0 }
};

void processArgs(int argc, char **argv, Arg *def, Options *opts)
{
	for(int i=1; i<argc; i++)
	{
		char *a = argv[i];
		if(a[0] == '-')
		{
			bool longArg = false;
			if(a[1] == '-')
			{
				a += 2;
				longArg = true;
			} else
			{
				a++;
			}

			Arg *d = def;
			bool found = false;
			while(d->name)
			{
				if(longArg && strcmp(d->name, a) == 0 ||
				   !longArg && *a == d->shortName)
				{
					char *offset = reinterpret_cast<char*>(opts)+d->optionOffset;
					switch(d->param)
					{
						case P_NONE:
							*(reinterpret_cast<bool*>(offset)) = true;
							break;
						case P_INTEGER:
							*(reinterpret_cast<int*>(offset)) = atoi(argv[i+1]);
							i++;
							break;
						case P_FLOAT:
							*(reinterpret_cast<float*>(offset)) = (float)atof(argv[i+1]);
							i++;
							break;
					}
					found = true;
					break;
				}
				d++;
			}
			
			if(!found)
				fprintf(stderr, "Unknown argument: %s\n", a);
		} else
		{
			opts->name = a;
		}

	}
}


int main(int argc, char **argv)
{
	Options o;
		
	o.cellWidth = -1;
	o.cellHeight = -1;
	o.rows = -1;
	o.cols = -1;
	o.minAngle = -1;
	o.maxAngle = -1;
	o.help = false;
	o.name = NULL;
	
	processArgs(argc, argv, options, &o);
	
	if(o.help || optind != argc-1 || argc <= 1 || (o.cellWidth <= 0 && o.cols <= 0) || (o.cellHeight <= 0 && o.rows <= 0))
	{
		fprintf(stderr, "Usage:\n\tVertexScanner [options] <png-file>\n\n");
		fprintf(stderr, "Options:\n");
		Arg *d = options;
		while(d->name)
		{
			const char *val = "";
			switch(d->param)
			{
				case P_INTEGER:
					val = " <int>";
					break;
				case P_FLOAT:
					val = " <float>";
					break;
			}
			fprintf(stderr, "\t-%c%s or --%s%s\n\t\t\t%s\n", d->shortName, val, d->name, val, d->desc);
			d++;
		}
		putc('\n', stderr);
		return -1;
	}
	
	ImageDesc img;
	loadPNG(o.name, &img);
	
	if(o.cols > 0 && o.cellWidth <= 0)
		o.cellWidth = img.width/o.cols;
	if(o.cellWidth > 0 && o.cols <= 0)
		o.cols = img.width/o.cellWidth;
	if(o.rows > 0 && o.cellHeight <= 0)
		o.cellHeight = img.height/o.rows;
	if(o.cellHeight > 0 && o.rows <= 0)
		o.rows = img.height/o.cellHeight;
	
	if(o.cellWidth*o.cols > img.width)
	{
		fprintf(stderr, "Invalid width: %d (image width is %d)\n",
				int(o.cellWidth*o.cols),
				int(img.width));
		return -1;
	}
	
	if(o.cellHeight*o.rows > img.height)
	{
		fprintf(stderr, "Invalid height: %d (image height is %d)\n",
				int(o.cellHeight*o.rows),
				int(img.height));
		return -1;
	}
	
	for(int cy=0; cy<o.rows; cy++)
	{
		for(int cx=0; cx<o.cols; cx++)
		{
			ImageDesc cell;
			cell.width = o.cellWidth;
			cell.height = o.cellHeight;
			// the image is a top-down image
			cell.pitch = img.pitch;
			// so data will point to the last row
			cell.data = img.data;
			// also offset it by the coordinates of the cell
			cell.data += (cx*o.cellWidth*4)+(cy*o.cellHeight*img.pitch);
			
			Vec2Array points;
			points.points = NULL;
			
			ScanParameters params;
			params.minimumAngle = o.minAngle;
			params.maximumAngle = o.maxAngle;
			
			findPoints(&params, &cell, &points);
			
			printf("\n// Cell %d %d\n", cx, cy);
			if(points.count > 0)
			{
				for(int i=0; i<points.count; i++)
				{
					Vec2 p = points.points[i];
					p.x -= o.cellWidth*0.5f;
					p.y -= o.cellHeight*0.5f;
					printf("%g %g\n", p.x, p.y);
				}
			}
			
			if(points.points)
				free(points.points);
		}
	}
	
}
