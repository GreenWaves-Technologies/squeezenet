from nntool.api import NNGraph
from nntool.stats.activation_ranges_collector import ActivationRangesCollector

import argparse
import argcomplete
from tqdm import tqdm
from PIL import Image
from glob import glob
import numpy as np
from preprocessing import preprocess
import pickle

def create_parser():
	# create the top-level parser
	parser = argparse.ArgumentParser(prog='collect_stats resnet')

	parser.add_argument('model_path', type=str,
						help='path to model')
	parser.add_argument('--quant_images', type=str, default="quant_data_ppm/*",
						help='where to store statistics')
	parser.add_argument('--stats_path', type=str, default="model/squeezenet_astats.pickle",
						help='where to store statistics')
	return parser

def main():
	parser = create_parser()
	argcomplete.autocomplete(parser)
	args = parser.parse_args()

	G = NNGraph.load_graph(args.model_path)
	# to CHW
	G.adjust_order()

	stats_collector = ActivationRangesCollector()
	for image in tqdm(glob(args.quant_images)):
		input_tensor = np.array(Image.open(image).convert(mode="RGB").resize((224, 224))).transpose(2, 0, 1)
		input_tensor = preprocess(input_tensor)
		stats_collector.collect_stats(G, [input_tensor])

	with open(args.stats_path, "wb") as f:
		pickle.dump(stats_collector.stats, f)


if __name__ == '__main__':
	main()
