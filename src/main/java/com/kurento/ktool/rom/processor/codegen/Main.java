package com.kurento.ktool.rom.processor.codegen;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.PosixParser;

import com.google.gson.JsonIOException;
import com.google.gson.JsonObject;

import freemarker.template.TemplateException;

public class Main {

	private static final String HELP = "h";
	private static final String VERBOSE = "v";
	private static final String LIST_GEN_FILES = "lf";
	private static final String ROM = "r";
	private static final String DEPROM = "dr";
	private static final String TEMPLATES_DIR = "t";
	private static final String CODEGEN = "c";
	private static final String DELETE = "d";
	private static final String NO_OVERWRITE = "n";
	private static final String CONFIG = "cf";
	private static final String INTERNAL_TEMPLATES = "it";
	private static final String SHOW_VALUES = "s";
	private static final String OUTPUT_MODEL = "o";

	public static void main(String[] args) throws IOException,
			TemplateException {

		Options options = configureOptions();

		CommandLine line = null;

		try {

			CommandLineParser parser = new PosixParser();
			line = parser.parse(options, args);

			if (line.hasOption(HELP) || !line.hasOption(ROM)) {
				printHelp(options);
				System.exit(0);
			}
		} catch (ParseException e) {
			System.err.println(e.getMessage());
			printHelp(options);
			System.exit(1);
		}

		KurentoRomProcessor krp = new KurentoRomProcessor();
		krp.setDeleteGenDir(line.hasOption(DELETE));
		krp.setVerbose(line.hasOption(VERBOSE));
		krp.setOverwrite(!line.hasOption(NO_OVERWRITE));
		krp.setListGeneratedFiles(line.hasOption(LIST_GEN_FILES));

		if (line.hasOption(TEMPLATES_DIR)) {
			krp.setTemplatesDir(getTemplatesDir(line));
		} else if (line.hasOption(INTERNAL_TEMPLATES)) {
			krp.setInternalTemplates(line.getOptionValue(INTERNAL_TEMPLATES));
		}

		krp.setConfig(getConfigContent(line));
		krp.setKmdFilesToGen(getKmdFiles(line));
		krp.setDependencyKmdFiles(getDependencyKmdFiles(line));
		krp.setOutputFile(getOutputModelFile(line));

		showValues(krp, line);

		krp.setCodeGenDir(getCodegenDir(line));

		Result result = krp.generateCode();

		if (result.isSuccess()) {
			System.out.println("Generation success");
		} else {
			System.out.println("Generation failed");
			result.showErrorsInConsole();
		}
	}

	private static void showValues(KurentoRomProcessor krp, CommandLine line) {
		if (!line.hasOption(SHOW_VALUES)) {
			return;
		}

		String[] keys = line.getOptionValues(SHOW_VALUES);

		krp.printValues(keys);
		System.exit(0);
	}

	@SuppressWarnings("static-access")
	private static Options configureOptions() {

		// create the Options
		Options options = new Options();
		options.addOption(VERBOSE, "verbose", false,
				"Prints source code while being generated.");

		options.addOption(HELP, "help", false, "Prints this message.");

		options.addOption(OptionBuilder
				.withLongOpt("rom")
				.withDescription(
						"A space separated list of Kurento Media Element "
								+ "Description (kmd) files or folders containing this files.")
				.hasArg().withArgName("ROM_FILE").isRequired().create(ROM));

		options.addOption(OptionBuilder
				.withLongOpt("deprom")
				.withDescription(
						"A space separated list of Kurento Media Element "
								+ "Description (kmd) files used as dependencies or folders containing this files.")
				.hasArg().withArgName("DEP_ROM_FILE").create(DEPROM));

		options.addOption(OptionBuilder.withLongOpt("templates")
				.withDescription("Directory that contains template files.")
				.hasArg().withArgName("TEMPLATES_DIR").create(TEMPLATES_DIR));

		options.addOption(OptionBuilder.withLongOpt("internal-templates")
				.withDescription("Directory that contains template files.")
				.hasArg().withArgName("TEMPLATES_DIR")
				.create(INTERNAL_TEMPLATES));

		options.addOption(OptionBuilder
				.withLongOpt("codegen")
				.withDescription(
						"Destination directory for generated files "
								+ "(required if --show-values or --output-model is not present.")
				.hasArg().withArgName("CODEGEN_DIR").create(CODEGEN));

		options.addOption(DELETE, "delete", false,
				"Delete destination directory before generating files.");

		options.addOption(LIST_GEN_FILES, "list-generated-files", false,
				"List in the standard output the names of generated files.");

		options.addOption(OptionBuilder.withLongOpt("config")
				.withDescription("Configuration file.").hasArg()
				.withArgName("CONFIGURATION_FILE").create(CONFIG));

		options.addOption(OptionBuilder
				.withLongOpt("show-values")
				.withDescription(
						"Show values for provided keys in kmd.json files.")
				.hasArgs().withArgName("LIST OF KEYS").create(SHOW_VALUES));

		options.addOption(OptionBuilder
				.withLongOpt("output-model")
				.withDescription(
						"Directory where the final model will be written.")
				.hasArgs().withArgName("DIR").create(OUTPUT_MODEL));

		options.addOption(OptionBuilder
				.withLongOpt("no-overwrite")
				.withDescription(
						"Do not overwrite files if they are already generated.")
				.create(NO_OVERWRITE));

		return options;
	}

	public static void printHelp(Options options) {
		HelpFormatter formatter = new HelpFormatter();
		formatter.printHelp("ktool-rom-processor", options);
	}

	private static List<Path> getDependencyKmdFiles(CommandLine line)
			throws IOException {

		if (line.hasOption(DEPROM)) {

			String[] kmdPathNames = line.getOptionValues(DEPROM);

			List<Path> kmdFiles = PathUtils
					.getPaths(kmdPathNames, "*.kmd.json");

			if (kmdFiles.isEmpty()) {
				String paths = null;
				for (String path : kmdPathNames) {
					if (paths == null) {
						paths = path;
					} else {
						paths = paths + ":" + path;
					}
				}
				System.err.println("No dependency kmd files found in paths: "
						+ paths);
				return Collections.emptyList();
			}

			return kmdFiles;

		} else {
			return Collections.emptyList();
		}
	}

	private static JsonObject getConfigContent(CommandLine line)
			throws JsonIOException, IOException {

		JsonObject configContents = new JsonObject();

		String configValue = line.getOptionValue(CONFIG);
		if (configValue != null) {
			Path configFile = Paths.get(configValue);
			if (!Files.exists(configFile)) {
				System.err.println("Config file '" + configFile
						+ "' does not exist or is not readable");
				System.exit(1);
			}
			configContents = KurentoRomProcessor.loadConfigFile(configFile);
		}

		return configContents;
	}

	private static Path getCodegenDir(CommandLine line) {

		if (!line.hasOption(CODEGEN)
				&& (!line.hasOption(SHOW_VALUES) && !line
						.hasOption(OUTPUT_MODEL))) {
			printHelp(configureOptions());
			System.exit(1);
		}

		if (line.hasOption(CODEGEN)) {

			File codegenDir = new File(line.getOptionValue(CODEGEN));
			if (codegenDir.exists()) {
				if (!codegenDir.canWrite()) {
					System.err.println("Codegen '" + codegenDir
							+ "' is not writable");
					System.exit(1);
				} else if (!codegenDir.isDirectory()) {
					System.err.println("Codegen '" + codegenDir
							+ "' is not a directory");
					System.exit(1);
				}
			}
			return codegenDir.toPath();
		} else {
			return null;
		}
	}

	private static Path getTemplatesDir(CommandLine line) {
		File templatesDir = new File(line.getOptionValue(TEMPLATES_DIR));

		if (templatesDir.exists()) {

			if (!templatesDir.canRead()) {
				System.err.println("TemplatesDir '" + templatesDir
						+ "' is not readable");
				System.exit(1);
			} else if (!templatesDir.isDirectory()) {
				System.err.println("TemplatesDir '" + templatesDir
						+ "' is not a directory");
				System.exit(1);
			}

			return templatesDir.toPath();

		} else {

			System.err.println("TemplatesDir '" + templatesDir
					+ "' doesn't exist");
			System.exit(1);
			return null;
		}
	}

	private static Path getOutputModelFile(CommandLine line) throws IOException {

		if (!line.hasOption(OUTPUT_MODEL)) {
			return null;
		}

		String outputPathName = line.getOptionValue(OUTPUT_MODEL);

		Path outputPath = Paths.get(outputPathName);

		if (!Files.exists(outputPath)) {
			Files.createDirectories(outputPath);
		}

		if (Files.isDirectory(outputPath) && Files.isWritable(outputPath)) {
			return outputPath;
		} else {
			System.err
					.println("Output directory option should be a writable directory");
			System.exit(1);
			return null;
		}
	}

	private static List<Path> getKmdFiles(CommandLine line) throws IOException {

		String[] kmdPathNames = line.getOptionValues(ROM);
		List<Path> kmdFiles = PathUtils.getPaths(kmdPathNames, "*.kmd.json");

		if (kmdFiles.isEmpty()) {
			System.err.println("No kmd files found in paths: "
					+ Arrays.toString(kmdPathNames));
			System.exit(1);
		}

		return kmdFiles;
	}

}
