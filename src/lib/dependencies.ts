import path, {dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import process from 'node:process';
import {execa} from 'execa';
import {scopedLogger} from './logger.js';

const logger = scopedLogger('dependencies');

const appDir = path.join(dirname(fileURLToPath(import.meta.url)), '..');

export const loadAll = async () => {
	if (process.env['NODE_ENV'] === 'production') {
		await loadUnbuffer();
	}
};

export const loadUnbuffer = async () => {
	await execa(path.join(appDir, 'sh', 'unbuffer.sh'));
};

export const hasRequired = async (): Promise<boolean> => {
	const bufferBool = await isUnbufferAvailable();

	return bufferBool;
};

export const isUnbufferAvailable = async (): Promise<boolean> => {
	try {
		await execa('which', ['unbuffer']);
		return true;
	} catch {
		logger.warn('`unbuffer\' command not found');
		return false;
	}
};
