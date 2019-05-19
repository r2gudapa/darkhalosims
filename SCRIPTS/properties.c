#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>
#include <stdlib.h>
#include <float.h>

int NumPart;
float mass = 0.413582;

struct particle_data
{
	float Pos[3];
} *P;

int main (int argc, char *argv[])
{
   char path[200], input_fname[200];
   sprintf(path, "/home/rgudapati/Documents/auto");
   int halo_number = atoi(argv[1]);
   int particles = atoi(argv[2]); // number of particles in the lowres halo

   sprintf(input_fname, "%s/%d.pos", path, halo_number);

//	printf("%s\n", input_fname);

  // char filename[] = input_fname;
   FILE *file = fopen (input_fname, "r" );
   if ( file != NULL )
   {

//	   printf("yes\n");
      struct particle_data *P = malloc(particles * sizeof(struct particle_data) + 1); 

      char line [ 128 ]; /* or other suitable maximum line size */
      int pnum = 0;

      while ( fgets ( line, sizeof line, file ) != NULL ) /* read a line */
      {
//	printf("yes\n");
	char * curr;
	curr = strtok(line, " ");
	int column = 0;
	while(curr != NULL) {
		P[pnum].Pos[column] = atof(curr);
		column++;
		curr = strtok(NULL, " ");
	}

	pnum++;
     
//	if(file) { printf("not null\n"); }
//	else { printf("IS null\n"); }

      }
    //  fclose ( file );

	bool trace = false;
      	
	if (trace) {
         for (int i = 0; i < pnum; i++) {
		float xv = P[i].Pos[0];
		float yv = P[i].Pos[1];
		float zv = P[i].Pos[2];

		//printf("PARTICLE %d: (%f, %f, %f)\n", i, xv, yv, zv);
         }
      	}
//      printf("reached\n");


      NumPart = pnum;

      float com_x = 0;
      float com_y = 0;
      float com_z = 0;
      float tot_mass = 0;

      float xmin = FLT_MAX;
      float ymin = FLT_MAX;
      float zmin = FLT_MAX;
      float xmax = FLT_MIN;
      float ymax = FLT_MIN;
      float zmax = FLT_MIN;

      for(int i = 1; i < NumPart; i++) {
	  
	      float x = P[i].Pos[0];
	      float y = P[i].Pos[1];
	      float z = P[i].Pos[2];	

	      com_x += mass * x;
	      com_y += mass * y;
	      com_z += mass * z;

	      tot_mass += mass;
		      
	      if (x < xmin) { xmin = x; }
	      if (y < ymin) { ymin = y; }
	      if (z < zmin) { zmin = z; }
	      if (x > xmax) { xmax = x; }
	      if (y > ymax) { ymax = y; }
	      if (z > zmax) { zmax = z; }
        }

        com_x = com_x / tot_mass;
        com_y = com_y / tot_mass;
        com_z = com_z / tot_mass;

	float boxx = xmax - xmin;
 	float boxy = ymax - ymin;
	float boxz = zmax - zmin;

	float boxsize = 0.0;

	if (boxx > boxy) {
		if (boxx > boxz) {
			boxsize = boxx;
		} else {
			boxsize = boxz;
		}
	} else {
		if (boxy > boxz) {
			boxsize = boxy;
		} else { 
			boxsize = boxz;
		}
	}
	
	boxsize = 5.0 * boxsize;
//	printf("works\n");
	printf("%f %f %f %f \n", com_x, com_y, com_z, boxsize);

//	printf("reached\n");

      
	free(P);	
   }
   else
   {
      perror ( input_fname ); /* why didn't the file open? */
   }
   return 0;
}
