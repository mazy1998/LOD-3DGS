import os
import numpy as np
from PIL import Image

def read_pfm(file):
    with open(file, 'rb') as f:
        color = None
        width = None
        height = None
        scale = None
        endian = None
        
        header = f.readline().decode('utf-8').rstrip()
        if header == 'PF':
            color = True    
        elif header == 'Pf':
            color = False
        else:
            raise Exception('Not a PFM file.')
        
        dim_match = f.readline().decode('utf-8').rstrip()
        dim_match = dim_match.split()
        width = int(dim_match[0])
        height = int(dim_match[1])
        
        scale = float(f.readline().decode('utf-8').rstrip())
        if scale < 0: # little-endian
            endian = '<'
            scale = -scale
        else:
            endian = '>' # big-endian
        
        data = np.fromfile(f, endian + 'f')
        shape = (height, width, 3) if color else (height, width)
        return np.reshape(data, shape), scale

def convert_pfm_to_png(input_dir, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    for filename in os.listdir(input_dir):
        if filename.endswith('.pfm'):
            pfm_path = os.path.join(input_dir, filename)
            png_filename = os.path.splitext(filename)[0] + '.png'
            png_path = os.path.join(output_dir, png_filename)
            
            # Read PFM file
            image, scale = read_pfm(pfm_path)
            
            # Normalize the image
            image = (image - np.min(image)) / (np.max(image) - np.min(image))
            image = (image * 255).astype(np.uint8)
            
            # Flip the image vertically
            image = np.flipud(image)
            
            # Save as PNG
            Image.fromarray(image).save(png_path)
            print(f"Converted {filename} to {png_filename}")

# Usage
input_directory = '/mnt/home/LOD/data/doll/rendered_depth_maps'
output_directory = '/mnt/home/LOD/data/doll/rendered_depth_maps_png'

convert_pfm_to_png(input_directory, output_directory)