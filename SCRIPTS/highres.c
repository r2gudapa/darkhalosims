#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

// This version of do_something only analyses a small box within the full simulation
// It prints out properties of all particles within a BSIZE box around COM 
// 	- no particles are skipped
// Set the limits of the box below

#define COMX 180866.250000
#define COMY 157656.312500
#define COMZ 90859.328125
#define BOXSIZE 24282.109375

float XMIN = COMX - (BOXSIZE / 2);
float XMAX = COMX + (BOXSIZE / 2);
float YMIN = COMY - (BOXSIZE / 2);
float YMAX = COMY + (BOXSIZE / 2);
float ZMIN = COMZ - (BOXSIZE / 2);
float ZMAX = COMZ + (BOXSIZE / 2);

struct io_header_1
{
  int npart[6];
  double mass[6];
  double time;
  double redshift;
  int flag_sfr;
  int flag_feedback;
  int npartTotal[6];
  int flag_cooling;
  int num_files;
  double BoxSize;
  double Omega0;
  double OmegaLambda;
  double HubbleParam;
  char fill[256 - 6 * 4 - 6 * 8 - 2 * 8 - 2 * 4 - 6 * 4 - 2 * 4 - 4 * 8];	// fills to 256 Bytes 
} header1;

int NumPart, Ngas;

struct particle_data
{
  float Pos[3];
  float Vel[3];
  float Mass;
  int Type;

  float Rho, U, Temp, Ne;
} *P;

int *Id;

double Time, Redshift;


/* Here we load a snapshot file. It can be distributed
 * onto several files (for files>1).
 * The particles are brought back into the order
 * implied by their ID's.
 * A unit conversion routine is called to do unit
 * conversion, and to evaluate the gas temperature.
 */
int main(int argc, char **argv)
{
  char path[200], input_fname[200], basename[200];
  int type, snapshot_number, files;

//printf("%f %f %f %f %f %f\n", XMIN, XMAX, YMIN, YMAX, ZMIN, ZMAX);

  sprintf(path, "/home/rgudapati/Documents/512_M025S09_v1");
  sprintf(basename, "512_M025S09_v1_snap");
 snapshot_number = 47;
  files = 1;			/* number of files per snapshot */
  
//	printf("%f %f %f %f %f %f\n", XMIN, XMAX, YMIN, YMAX, ZMIN, ZMAX);

  sprintf(input_fname, "%s/%s_%03d", path, basename, snapshot_number);
  load_snapshot(input_fname, files);

 // for (int i = 0; i < 6; i++) {
 // printf("NP: %d\n", header1.npart[i]);
 // }
  //reordering();			/* call this routine only if your ID's are set properly */

  //unit_conversion();		/* optional stuff */

  // CHOOSE EITHER PARTIVIEW OR TIPSY ASCII OUTPUT FILE HERE
//  positions(); // position only - use for partiview, topcat
 //tipsy();
  // posvel(); // position, velocity
 //posid();
  // idonly();
// number();
 //redshift();

//  printf("is that all you got?!\n");

}

// ignore this: the skip size is still one -- this is the max
// number of particles the analysis can handle
#define skip_size 4

void redshift(void) {
	printf("%f\n", header1.redshift);
}

int posid(void) {
	
	//printf("%d\n", NumPart);	

//	printf("%f\n", header1.redshift);
	float x, y, z = 0.0;
	int id = 0;
	for (int i = 1; i <= NumPart; i++) {
		x = P[i].Pos[0];
		y = P[i].Pos[1];
		z = P[i].Pos[2];
		id = Id[i];

		printf("%012d %f %f %f\n", id, x, y, z);
	}
	
}

int number(void) {
	printf("%d\n", NumPart);
}

int idonly(void) {

	for (int i = 1; i <= NumPart; i++) {
		printf("%012d\n",Id[i]);
	}
}

int positions(void)
{
	float x, y, z = 0;
	for (int i = 1; i <= NumPart; i++) {
		x = P[i].Pos[0];
		y = P[i].Pos[1];
		z = P[i].Pos[2];
		
		printf("%f %f %f\n", x, y, z);

	}
}

int posvel(void)
{
	float x, y, z, v1, v2, v3 = 0;
	for (int i = 1; i <= NumPart; i++) {
		x = P[i].Pos[0];
		y = P[i].Pos[1];
		z = P[i].Pos[2];

		v1 = P[i].Vel[0];
		v2 = P[i].Vel[1];
		v3 = P[i].Vel[2];
	
		printf("%f %f %f %f %f %f\n", x, y, z, v1, v2, v3);

	}
}

int tipsy(void)
{
	printf("%d, 3, %f\n", NumPart, header1.time);
       	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[1].Mass);
	}
	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[i].Pos[0]); 
	}	
	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[i].Pos[1]); 
	}
	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[i].Pos[2]); 
	}
	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[i].Vel[0]);
	}
	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[i].Vel[1]); 
	}
	for (int i = 1; i <= NumPart; i++) {
		printf("%f\n",P[i].Vel[2]);
	}
}


/* this template shows how one may convert from Gadget's units
 * to cgs units.
 * In this example, the temperate of the gas is computed.
 * (assuming that the electron density in units of the hydrogen density
 * was computed by the code. This is done if cooling is enabled.)
 */
int unit_conversion(void)
{
  double GRAVITY, BOLTZMANN, PROTONMASS;
  double UnitLength_in_cm, UnitMass_in_g, UnitVelocity_in_cm_per_s;
  double UnitTime_in_s, UnitDensity_in_cgs, UnitPressure_in_cgs, UnitEnergy_in_cgs;
  double G, Xh, HubbleParam;

  int i;
  double MeanWeight, u, gamma;

  /* physical constants in cgs units */
  GRAVITY = 6.672e-8;
  BOLTZMANN = 1.3806e-16;
  PROTONMASS = 1.6726e-24;

  /* internal unit system of the code */
  UnitLength_in_cm = 3.085678e21;	/*  code length unit in cm/h */
  UnitMass_in_g = 1.989e43;	/*  code mass unit in g/h */
  UnitVelocity_in_cm_per_s = 1.0e5;

  UnitTime_in_s = UnitLength_in_cm / UnitVelocity_in_cm_per_s;
  UnitDensity_in_cgs = UnitMass_in_g / pow(UnitLength_in_cm, 3);
  UnitPressure_in_cgs = UnitMass_in_g / UnitLength_in_cm / pow(UnitTime_in_s, 2);
  UnitEnergy_in_cgs = UnitMass_in_g * pow(UnitLength_in_cm, 2) / pow(UnitTime_in_s, 2);

  G = GRAVITY / pow(UnitLength_in_cm, 3) * UnitMass_in_g * pow(UnitTime_in_s, 2);


  Xh = 0.76;			/* mass fraction of hydrogen */
  HubbleParam = 0.65;


  for(i = 1; i <= NumPart; i++)
    {
      if(P[i].Type == 0)	/* gas particle */
	{
	  MeanWeight = 4.0 / (3 * Xh + 1 + 4 * Xh * P[i].Ne) * PROTONMASS;

	  /* convert internal energy to cgs units */

	  u = P[i].U * UnitEnergy_in_cgs / UnitMass_in_g;

	  gamma = 5.0 / 3;

	  /* get temperature in Kelvin */

	  P[i].Temp = MeanWeight / BOLTZMANN * (gamma - 1) * u;
	}
    }
}

float skip_rows[3*sizeof(float)];
int skip_id = 1;

/* this routine loads particle data from Gadget's default
 * binary file format. (A snapshot may be distributed
 * into multiple files.
 */
int load_snapshot(char *fname, int files)
{
  FILE *fd;
  char buf[200];
  int i, j, k, dummy, ntot_withmasses;
  int t, n, off, pc, pc_new, pc_sph;

#define SKIP fread(&dummy, sizeof(dummy), 1, fd);
	//printf("load_snapshot...\n");
  for(i = 0, pc = 1; i < files; i++, pc = pc_new)
    {
      if(files > 1)
	sprintf(buf, "%s.%d", fname, i);
      else
	sprintf(buf, "%s", fname);

      if(!(fd = fopen(buf, "r")))
	{
	  //printf("can't open file `%s`\n", buf);
	  exit(0);
	}

      //printf("reading `%s' ...\n", buf);
     //fflush(stdout);

      fread(&dummy, sizeof(dummy), 1, fd);

      fread(&dummy, sizeof(dummy), 1, fd);
      fread(&dummy, sizeof(dummy), 1, fd);
      fread(&dummy, sizeof(dummy), 1, fd);
      fread(&dummy, sizeof(dummy), 1, fd);
      
      fread(&header1, sizeof(header1), 1, fd);
      fread(&dummy, sizeof(dummy), 1, fd); 
	
      if(files == 1)
	{
	  for(k = 0, NumPart = 0, ntot_withmasses = 0; k < 5; k++)
	    NumPart += (header1.npart[k]) / skip_size;
	    //NumPart *= 100;
	  Ngas = header1.npart[0];
	}
      else
	{
	  for(k = 0, NumPart = 0, ntot_withmasses = 0; k < 5; k++)
	    NumPart += (header1.npartTotal[k]) / skip_size;
	    //NumPart *= 100;
	  Ngas = header1.npartTotal[0];
	}

      for(k = 0, ntot_withmasses = 0; k < 5; k++)
	{
	  if(header1.mass[k] == 0)
	    ntot_withmasses += (header1.npart[k]) / skip_size;
	}

      if(i == 0)
	allocate_memory();

      SKIP;
      // position (3)
      // fread(&P[pc_new].Pos[0], sizeof(float), 3, fd);
      int np = 0;
      int pos = 0;
      //printf("putting in positions...\n");
      for(k = 0, pc_new = pc; k < 6; k++)
	{
	  for(n = 0; n < header1.npart[k];)
	    {
		// find the in_x = abs(x_pos - COM) < BSIZE
		// only read in if (in_x && in_y && in_z)

		   fread(skip_rows, sizeof(float), 3, fd);

//			printf("done fread.\n");

		   bool in_x = (skip_rows[0] > XMIN) && (skip_rows[0] < XMAX);
		   bool in_y = (skip_rows[1] > YMIN) && (skip_rows[1] < YMAX);
		   bool in_z = (skip_rows[2] > ZMIN) && (skip_rows[2] < ZMAX);

		   if (in_x && in_y && in_z) {
			P[pc_new].Pos[0] = skip_rows[0];
			P[pc_new].Pos[1] = skip_rows[1];
			P[pc_new].Pos[2] = skip_rows[2];
			pc_new++;
			np++;
		   }
		   n++;
		 //  printf("n = %d, np = %d\n", n, np);
	    }
	}
      SKIP;
      //printf("done positions.\n");

      NumPart = np;

      SKIP;
      // velocity (3)
      // fread(&P[pc_new].Vel[0], sizeof(float), 3, fd);
      for(k = 0, pc_new = pc; k < 6; k++)
	{
	for(n = 0; n < header1.npart[k];)
	    {
		    
		// find the in_x = abs(x_pos - COM) < BSIZE
		// only read in if (in_x && in_y && in_z)

		   fread(skip_rows, sizeof(float), 3, fd);

		   bool in_x = (P[pc_new].Pos[0] > XMIN) && (P[pc_new].Pos[0] < XMAX);
		   bool in_y = (P[pc_new].Pos[1] > YMIN) && (P[pc_new].Pos[1] < YMAX);
		   bool in_z = (P[pc_new].Pos[2] > ZMIN) && (P[pc_new].Pos[2] < ZMAX);

		   if (in_x && in_y && in_z) {
			P[pc_new].Vel[0] = skip_rows[0];
			P[pc_new].Vel[1] = skip_rows[1];
			P[pc_new].Vel[2] = skip_rows[2];
			pc_new++;
		   }
		   n++;
	    }
	}
      SKIP;


      SKIP;
      // id (1)
      // fread(&Id[pc_new], sizeof(int), 1, fd);
      for(k = 0, pc_new = pc; k < 6; k++)
	{
	  for(n = 0; n < header1.npart[k];)
	    { 
		// find the in_x = abs(x_pos - COM) < BSIZE
		// only read in if (in_x && in_y && in_z)

		   fread(&skip_id, sizeof(int), 1, fd);

		   bool in_x = (P[pc_new].Pos[0] > XMIN) && (P[pc_new].Pos[0] < XMAX);
		   bool in_y = (P[pc_new].Pos[1] > YMIN) && (P[pc_new].Pos[1] < YMAX);
		   bool in_z = (P[pc_new].Pos[2] > ZMIN) && (P[pc_new].Pos[2] < ZMAX);

		   if (in_x && in_y && in_z) {
			Id[pc_new] = skip_id;
			pc_new++;
		   }
		   n++;
	    }
	}
      SKIP;

// NOTHING BELOW HERE HAS BEEN MODIFIED IN THIS FUNCTION

      if(ntot_withmasses > 0)
	SKIP;
      for(k = 0, pc_new = pc; k < 6; k++)
	{
	  for(n = 0; n < header1.npart[k];)
	    {
	      P[pc_new].Type = k;

	      	if(header1.mass[k] == 0) {
			if (n % skip_size == 0) { 
				fread(&P[pc_new].Mass, sizeof(float), 1, fd);
				pc_new++;
				n++; 
	      		} else if ((header1.npart[k] - n) >= skip_size) {
				fread(skip_rows, sizeof(float) * 1 * (skip_size - 1), 1, fd);
				n = n + (skip_size - 1);
			} else {
				int rows_left = header1.npart[k] - n;
				fread(skip_rows, sizeof(float) * 1 * rows_left, 1, fd);
				n++;
			}

	      	} else {
			if (n % skip_size == 0) { 
				P[pc_new].Mass = header1.mass[k];
				pc_new++;
				n++; 
	      		} else if ((header1.npart[k] - n) >= skip_size) {
				fread(skip_rows, sizeof(float) * 1 * (skip_size - 1), 1, fd);
				n = n + (skip_size - 1);
			} else {
				int rows_left = header1.npart[k] - n;
				fread(skip_rows, sizeof(float) * 1 * rows_left, 1, fd);
				n++;
			}
		}

	    }
	}
      if(ntot_withmasses > 0)
	SKIP;


      if(header1.npart[0] > 0)
	{
	  SKIP;
	  for(n = 0, pc_sph = pc; n < header1.npart[0];)
	    {
		if (n % skip_size == 0) { 
				fread(&P[pc_sph].U, sizeof(float), 1, fd);
				pc_sph++;
				n++; 
	      		} else if ((header1.npart[0] - n) >= skip_size) {
				fread(skip_rows, sizeof(float) * 1 * (skip_size - 1), 1, fd);
				n = n + (skip_size - 1);
			} else {
				int rows_left = header1.npart[0] - n;
				fread(skip_rows, sizeof(float) * 1 * rows_left, 1, fd);
				n++;
			}
	    }
	  SKIP;

	  SKIP;
	  for(n = 0, pc_sph = pc; n < header1.npart[0];)
	    {
	      	if (n % skip_size == 0) { 
				fread(&P[pc_sph].Rho, sizeof(float), 1, fd);
				pc_sph++;
				n++; 
	      		} else if ((header1.npart[0] - n) >= skip_size) {
				fread(skip_rows, sizeof(float) * 1 * (skip_size - 1), 1, fd);
				n = n + (skip_size - 1);
			} else {
				int rows_left = header1.npart[0] - n;
				fread(skip_rows, sizeof(float) * 1 * rows_left, 1, fd);
				n++;
			}
	    }
	  SKIP;

	  if(header1.flag_cooling)
	    {
	      SKIP;
	      for(n = 0, pc_sph = pc; n < header1.npart[0];)
		{
		 	if (n % skip_size == 0) { 
				fread(&P[pc_sph].Ne, sizeof(float), 1, fd);
				pc_sph++;
				n++; 
	      		} else if ((header1.npart[0] - n) >= skip_size) {
				fread(skip_rows, sizeof(float) * 1 * (skip_size - 1), 1, fd);
				n = n + (skip_size - 1);
			} else {
				int rows_left = header1.npart[0] - n;
				fread(skip_rows, sizeof(float) * 1 * rows_left, 1, fd);
				n++;
			}
		}
	      SKIP;
	    }
	  else
	    for(n = 0, pc_sph = pc; n < header1.npart[0];)
	      {
			if (n % skip_size == 0) { 
				P[pc_sph].Ne = 1.0;
				pc_sph++;
				n++; 
	      		} else if ((header1.npart[0] - n) >= skip_size) {
				fread(skip_rows, sizeof(float) * 1 * (skip_size - 1), 1, fd);
				n = n + (skip_size - 1);
			} else {
				int rows_left = header1.npart[0] - n;
				fread(skip_rows, sizeof(float) * 1 * rows_left, 1, fd);
				n++;
			}
	      }
	}

      fclose(fd);
    }


  Time = header1.time;
  Redshift = header1.time;

}




/* this routine allocates the memory for the 
 * particle data.
 */
int allocate_memory(void)
{
  //printf("allocating memory...\n");

  if(!(P = malloc(NumPart * sizeof(struct particle_data))))
    {
      fprintf(stderr, "failed to allocate memory.\n");
      exit(0);
    }

  P--;				/* start with offset 1 */


  if(!(Id = malloc(NumPart * sizeof(int))))
    {
      fprintf(stderr, "failed to allocate memory.\n");
      exit(0);
    }

  Id--;				/* start with offset 1 */

  //printf("allocating memory...done\n");
}




/* This routine brings the particles back into
 * the order of their ID's.
 * NOTE: The routine only works if the ID's cover
 * the range from 1 to NumPart !
 * In other cases, one has to use more general
 * sorting routines.
 */
int reordering(void)
{
  int i,j;
  int idsource, idsave, dest;
  struct particle_data psave, psource;


  if(0){
    //printf("reordering....\n");
  }

  for(i=1; i<=NumPart; i++)
    {
      if(Id[i] != i)
	{
	  psource= P[i];
	  idsource=Id[i];
	  dest=Id[i];

	  do
	    {
	      psave= P[dest];
	      idsave=Id[dest];

	      P[dest]= psource;
	      Id[dest]= idsource;
	      
	      if(dest == i) 
		break;

	      psource= psave;
	      idsource=idsave;

	      dest=idsource;
	    }
	  while(1);
	}
    }

  if(0){  
    //printf("done.\n");
  }

  Id++;   
  free(Id);

  if(0){
 // printf("space for particle ID freed\n");
  }
}
